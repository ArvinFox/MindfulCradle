import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';

// ─── Step data ────────────────────────────────────────────────────────────────

/// Fraction of the screen (0–1) used when there is no GlobalKey to target.
class RelRect {
  final double l, t, r, b;
  const RelRect(this.l, this.t, this.r, this.b);
  Rect toRect(Size s) =>
      Rect.fromLTRB(s.width * l, s.height * t, s.width * r, s.height * b);
}

class TutorialStep {
  final int switchToTab; // -1 = keep current tab
  final GlobalKey? navKey; // spotlight this nav-bar item precisely
  final RelRect? relRect; // OR spotlight this screen-fraction area
  final double padding; // inflate the spotlight rect
  final String titleEn, titleSi, descEn, descSi;

  const TutorialStep({
    required this.switchToTab,
    this.navKey,
    this.relRect,
    this.padding = 12,
    required this.titleEn,
    required this.titleSi,
    required this.descEn,
    required this.descSi,
  });
}

// ─── Public widget ────────────────────────────────────────────────────────────

/// Drop this into a [Stack] on top of the main app.
/// [steps] must be provided by the host (MainScreen) so GlobalKeys map to
/// the actual nav-bar item widgets.
class CoachMarkTutorial extends StatefulWidget {
  final List<TutorialStep> steps;
  final ValueChanged<int> onTabSwitch;
  final VoidCallback onDone;

  const CoachMarkTutorial({
    super.key,
    required this.steps,
    required this.onTabSwitch,
    required this.onDone,
  });

  @override
  State<CoachMarkTutorial> createState() => _CoachMarkTutorialState();
}

class _CoachMarkTutorialState extends State<CoachMarkTutorial>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  bool _finishing = false;

  late final AnimationController _anim;
  late Animation<double> _fade;
  RectTween? _spotTween;
  Rect? _currentSpot;
  Rect? _prevSpot;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    // Kick off the first step animation after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateToStep(0));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Spotlight rect resolution ───────────────────────────────────────────────

  Rect? _resolveRect(int stepIdx, Size screen) {
    final s = widget.steps[stepIdx];
    if (s.navKey != null) {
      final rb = s.navKey!.currentContext?.findRenderObject() as RenderBox?;
      if (rb != null && rb.hasSize) {
        final pos = rb.localToGlobal(Offset.zero);
        return (pos & rb.size).inflate(s.padding);
      }
    }
    if (s.relRect != null) {
      return s.relRect!.toRect(screen).inflate(s.padding);
    }
    return null; // full-screen (no hole)
  }

  // ── Step transition ─────────────────────────────────────────────────────────

  void _animateToStep(int idx) {
    if (!mounted) return;
    final screen = MediaQuery.of(context).size;
    final newSpot = _resolveRect(idx, screen);
    _spotTween = RectTween(begin: _prevSpot ?? newSpot, end: newSpot);
    _prevSpot = newSpot;
    _anim.reset();
    _anim.forward();
    setState(() => _currentSpot = newSpot);
  }

  void _prev() {
    if (_step > 0) {
      HapticFeedback.lightImpact();
      final prev = _step - 1;
      final switchTo = widget.steps[prev].switchToTab;
      if (switchTo >= 0) widget.onTabSwitch(switchTo);
      setState(() => _step = prev);
      Future.delayed(
        const Duration(milliseconds: 120),
        () => _animateToStep(prev),
      );
    }
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_step < widget.steps.length - 1) {
      final next = _step + 1;
      final switchTo = widget.steps[next].switchToTab;
      if (switchTo >= 0) widget.onTabSwitch(switchTo);
      setState(() => _step = next);
      // Delay resolving positions so the tab switch can rebuild nav items.
      Future.delayed(
        const Duration(milliseconds: 120),
        () => _animateToStep(next),
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    HapticFeedback.mediumImpact();

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final uid = auth.user?.id;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'isTutorialDone': true,
        });
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tutorial_done', true);
    } catch (_) {
      // Never block navigation on errors
    }

    if (mounted) widget.onDone();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSinhala =
        Provider.of<LanguageProvider>(context, listen: false).currentLang ==
        'si';
    final step = widget.steps[_step];
    final screen = MediaQuery.of(context).size;
    final mq = MediaQuery.of(context);
    final isLast = _step == widget.steps.length - 1;

    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) {
        final spot = _spotTween?.evaluate(_fade) ?? _currentSpot;

        // Decide where to position the callout card.
        final calloutBelow = spot == null
            ? null // centred
            : spot.center.dy < screen.height * 0.55;

        return Stack(
          children: [
            // ── Dark overlay with hole ────────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(
                  spotlight: spot,
                  progress: _fade.value,
                ),
              ),
            ),

            // ── Callout card ──────────────────────────────────────
            _buildCallout(
              context,
              step,
              isSinhala,
              spot,
              calloutBelow,
              screen,
              mq,
            ),

            // ── Top skip pill (hidden on last step) ───────────────
            if (!isLast)
              Positioned(
                top: mq.padding.top + 16,
                right: 20,
                child: GestureDetector(
                  onTap: _finishing ? null : _finish,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      isSinhala ? 'මඟ හරින්න' : 'Skip',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCallout(
    BuildContext context,
    TutorialStep step,
    bool isSinhala,
    Rect? spot,
    bool? calloutBelow, // null = centred
    Size screen,
    MediaQueryData mq,
  ) {
    final isFirst = _step == 0;
    final isLast = _step == widget.steps.length - 1;

    final card = Container(
      constraints: BoxConstraints(
        maxWidth: screen.width - 48,
        minWidth: screen.width * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: DefaultTextStyle.merge(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator dots
            Row(
              children: [
                ...List.generate(widget.steps.length, (i) {
                  final active = i == _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    margin: const EdgeInsets.only(right: 4),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
                const Spacer(),
                // Step counter
                Text(
                  '${_step + 1} / ${widget.steps.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              isSinhala ? step.titleSi : step.titleEn,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                height: 1.2,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 6),

            // Description
            Text(
              isSinhala ? step.descSi : step.descEn,
              style: GoogleFonts.roboto(
                fontSize: 13.5,
                color: AppColors.textMuted,
                height: 1.55,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 18),

            // Buttons
            Row(
              children: [
                // Previous (hidden on first step)
                if (!isFirst)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _finishing ? null : _prev,
                      child: Text(
                        isSinhala ? 'පෙර' : 'Previous',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                if (!isFirst) const SizedBox(width: 10),
                Expanded(
                  flex: (isFirst || isLast) ? 1 : 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _finishing ? null : _next,
                    child: _finishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLast
                                    ? (isSinhala ? 'ආරම්භ කරන්න' : "Let's Go!")
                                    : (isFirst
                                          ? (isSinhala
                                                ? 'සංචාරය ආරම්භ'
                                                : 'Start Tour')
                                          : (isSinhala ? 'ඊළඟ' : 'Next')),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isLast
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 17,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // ── Positioning ──────────────────────────────────────────────────────────

    if (calloutBelow == null || spot == null) {
      // Centred on screen (welcome / done steps)
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: card,
        ),
      );
    }

    const sideMargin = 24.0;
    const gap = 16.0; // gap between spotlight and callout

    if (calloutBelow) {
      return Positioned(
        top: spot.bottom + gap,
        left: sideMargin,
        right: sideMargin,
        child: card,
      );
    } else {
      return Positioned(
        bottom: screen.height - spot.top + gap,
        left: sideMargin,
        right: sideMargin,
        child: card,
      );
    }
  }
}

// ─── CustomPainter ─────────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect? spotlight;
  final double progress;

  const _SpotlightPainter({this.spotlight, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayColor = Color.lerp(
      Colors.transparent,
      const Color(0xCC000000), // ~80% black
      progress,
    )!;

    if (spotlight == null || spotlight == Rect.zero) {
      canvas.drawRect(Offset.zero & size, Paint()..color = overlayColor);
      return;
    }

    // Draw overlay with a rounded-rect hole
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(spotlight!, const Radius.circular(18)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = overlayColor);

    // Glowing border around spotlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(spotlight!, const Radius.circular(18)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.spotlight != spotlight || old.progress != progress;
}
