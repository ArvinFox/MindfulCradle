import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

class _TutorialSlide {
  final List<Color> gradient;
  final IconData icon;
  final String tagEn;
  final String tagSi;
  final String titleEn;
  final String titleSi;
  final String descEn;
  final String descSi;
  final List<_MiniChip> chips;

  const _TutorialSlide({
    required this.gradient,
    required this.icon,
    required this.tagEn,
    required this.tagSi,
    required this.titleEn,
    required this.titleSi,
    required this.descEn,
    required this.descSi,
    this.chips = const [],
  });
}

class _MiniChip {
  final IconData icon;
  final String labelEn;
  final String labelSi;
  const _MiniChip(this.icon, this.labelEn, this.labelSi);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AppTutorialScreen extends StatefulWidget {
  const AppTutorialScreen({super.key});

  @override
  State<AppTutorialScreen> createState() => _AppTutorialScreenState();
}

class _AppTutorialScreenState extends State<AppTutorialScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _pageFraction = 0.0;
  bool _completing = false;

  late final AnimationController _iconAnim;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;

  // ── Slide definitions ──────────────────────────────────────────────────────
  static const _slides = <_TutorialSlide>[
    _TutorialSlide(
      gradient: [Color(0xFF1F6F78), Color(0xFF3AA8A3)],
      icon: Icons.favorite_rounded,
      tagEn: 'Welcome',
      tagSi: 'සාදරයෙන් පිළිගනිමු',
      titleEn: 'Welcome to\nMindful Cradle',
      titleSi: 'Mindful Cradle\nවෙත සාදරයෙන්',
      descEn:
          "Your caring companion throughout pregnancy. Let's take a quick tour of everything we've prepared for your journey.",
      descSi:
          'ගැබ්ගෙන සිටියදී ඔබේ සෙනෙහෙසම සහකාරිය. ඔබේ ගමනට අප සූදානම් කළ සියල්ල ගැන කෙටි සංචාරයක් කරමු.',
    ),
    _TutorialSlide(
      gradient: [Color(0xFF6C63FF), Color(0xFF9B88FF)],
      icon: Icons.play_circle_outline_rounded,
      tagEn: 'Mindfulness Sessions',
      tagSi: 'සිහිය සැසි',
      titleEn: 'Guided\nMeditation Videos',
      titleSi: 'මෙනෙහිකිරීම\nවීඩියෝ',
      descEn:
          'Watch curated mindfulness and guided meditation videos. Sessions unlock progressively as you complete each one.',
      descSi:
          'ප්‍රවීණ mindfulness සහ මෙනෙහිකිරීම වීඩියෝ නරඹන්න. ඔබ එක් සැසියක් සම්පූර්ණ කරන විට ඊළඟ සැසිය අගුළු හැරේ.',
      chips: [
        _MiniChip(
          Icons.lock_open_rounded,
          'Progressive Unlock',
          'ක්‍රමිකව අගුළු හැරේ',
        ),
        _MiniChip(
          Icons.language_rounded,
          'Sinhala & English',
          'සිංහල සහ ඉංග්‍රීසි',
        ),
        _MiniChip(Icons.hd_rounded, 'HD Quality', 'HD ගුණාත්මකභාවය'),
      ],
    ),
    _TutorialSlide(
      gradient: [Color(0xFF2979FF), Color(0xFF40C4FF)],
      icon: Icons.assignment_outlined,
      tagEn: 'Mental Health',
      tagSi: 'මානසික සෞඛ්‍යය',
      titleEn: 'Evidence-Based\nAssessments',
      titleSi: 'සාක්ෂි-පදනම්\nඇගයීම්',
      descEn:
          'Complete DASS-21, MAAS & PWS-18 questionnaires to understand and monitor your emotional wellbeing over time.',
      descSi:
          'ඔබේ මානසික සෞඛ්‍ය නිරීක්ෂණය සඳහා DASS-21, MAAS සහ PWS-18 ප්‍රශ්නාවලිය සම්පූර්ණ කරන්න.',
      chips: [
        _MiniChip(Icons.psychology_outlined, 'DASS-21', 'DASS-21'),
        _MiniChip(Icons.self_improvement_rounded, 'MAAS', 'MAAS'),
        _MiniChip(Icons.pregnant_woman_rounded, 'PWS-18', 'PWS-18'),
      ],
    ),
    _TutorialSlide(
      gradient: [Color(0xFF2D9D78), Color(0xFF80E27E)],
      icon: Icons.smart_toy_rounded,
      tagEn: 'AI Assistant',
      tagSi: 'AI සහකාරයා',
      titleEn: 'Your Personal\nAI Companion',
      titleSi: 'ඔබේ පෞද්ගලික\nAI සහකාරයා',
      descEn:
          'Ask anything about pregnancy, mental health, or everyday concerns. Our AI chatbot is always ready to help you, anytime.',
      descSi:
          'ගැබ්ගෙන සිටීම, මානසික සෞඛ්‍යය හෝ දෛනික ගැටළු ගැන ඕනෑම දෙයක් අසන්න. AI chatbot සෑම විටම ඔබ සමඟ.',
      chips: [
        _MiniChip(Icons.history_rounded, 'Chat History', 'කතා ඉතිහාසය'),
        _MiniChip(Icons.search_rounded, 'Knowledge Base', 'දැනුම් පදනම'),
        _MiniChip(Icons.translate_rounded, 'Bilingual', 'ද්විභාෂා'),
      ],
    ),
    _TutorialSlide(
      gradient: [Color(0xFFE06C8B), Color(0xFFF79FC7)],
      icon: Icons.mood_rounded,
      tagEn: 'Wellbeing',
      tagSi: 'යහශ්‍රිය',
      titleEn: 'Mood & Journal\nTracking',
      titleSi: 'මනෝභාවය හා\nජර්නල් ලුහුබැඳීම',
      descEn:
          'Log your mood daily and write journal entries to reflect on your journey. Small steps make the biggest differences.',
      descSi:
          'ඔබේ දෛනික මනෝභාවය ලොග් කර ජර්නල් ලියන්න. කුඩා පියවර ලොකු වෙනස්කම් ඇති කරයි.',
      chips: [
        _MiniChip(Icons.bar_chart_rounded, 'Mood Trends', 'මනෝ ප්‍රවණතා'),
        _MiniChip(
          Icons.edit_note_rounded,
          'Journal Entries',
          'ජර්නල් ඇතුළත් කිරීම්',
        ),
        _MiniChip(
          Icons.calendar_today_rounded,
          'Daily Streaks',
          'දෛනික ශ්‍රේණි',
        ),
      ],
    ),
    _TutorialSlide(
      gradient: [Color(0xFFE28E28), Color(0xFFFFB74D)],
      icon: Icons.workspace_premium_rounded,
      tagEn: 'Achievements',
      tagSi: 'ජයග්‍රහණ',
      titleEn: 'Earn Badges &\nMilestones',
      titleSi: 'සම්මාන හා\nසන්ධිස්ථාන',
      descEn:
          'Complete activities across the app to unlock achievement badges. Celebrate every milestone on your wellness journey.',
      descSi:
          'App හරහා ක්‍රියාකාරකම් සම්පූර්ණ කර achievement badges unlock කරන්න. ඔබේ ගමනේ සෑම සන්ධිස්ථානයක්ම සමරන්න.',
      chips: [
        _MiniChip(Icons.star_rounded, 'Milestones', 'සන්ධිස්ථාන'),
        _MiniChip(Icons.military_tech_rounded, 'Badges', 'සම්මාන'),
        _MiniChip(Icons.trending_up_rounded, 'Progress', 'ප්‍රගතිය'),
      ],
    ),
    _TutorialSlide(
      gradient: [Color(0xFF1F6F78), Color(0xFF3AA8A3)],
      icon: Icons.rocket_launch_rounded,
      tagEn: "Ready!",
      tagSi: 'සූදානම්!',
      titleEn: "You're All\nSet to Begin!",
      titleSi: 'ඔබ ආරම්භ\nකිරීමට සූදානම්!',
      descEn:
          'Everything is ready for your mindfulness journey. Start exploring, track your wellbeing, and embrace every beautiful moment.',
      descSi:
          'ඔබේ mindfulness ගමනට සියල්ල සූදානම්. Explore කරන්න, ඔබේ යහශ්‍රිය නිරීක්ෂණය කරන්න, සෑම මනරම් මොහොතක්ම ගෙන ගොස් ආලිංගනය කරන්න.',
    ),
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _iconAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _iconScale = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _iconAnim, curve: Curves.elasticOut));
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnim,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );
    _iconAnim.forward();

    _pageController.addListener(() {
      if (mounted) {
        setState(() => _pageFraction = _pageController.page ?? 0.0);
      }
    });
  }

  @override
  void dispose() {
    _iconAnim.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Gradient interpolation ─────────────────────────────────────────────────

  List<Color> _interpolatedGradient() {
    final int a = _pageFraction.floor().clamp(0, _slides.length - 1);
    final int b = (_pageFraction.ceil()).clamp(0, _slides.length - 1);
    if (a == b) return _slides[a].gradient;
    final double t = _pageFraction - a;
    return [
      Color.lerp(_slides[a].gradient[0], _slides[b].gradient[0], t)!,
      Color.lerp(_slides[a].gradient[1], _slides[b].gradient[1], t)!,
    ];
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _iconAnim.reset();
    _iconAnim.forward();
  }

  Future<void> _finish() async {
    if (_completing) return;
    setState(() => _completing = true);
    HapticFeedback.mediumImpact();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'isTutorialDone': true},
        );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tutorial_done', true);
    } catch (_) {
      // Don't block navigation on Firestore errors
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/main-screen', (_) => false);
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSinhala =
        Provider.of<LanguageProvider>(context, listen: false).currentLang ==
        'si';
    final grad = _interpolatedGradient();
    final mq = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // ── Animated gradient background ────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: grad,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // ── Decorative blobs ────────────────────────────────
              _buildBlobs(mq.size),

              // ── PageView ────────────────────────────────────────
              PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (_, i) => _buildSlide(_slides[i], isSinhala, mq),
              ),

              // ── Top bar: counter + skip ──────────────────────────
              Positioned(
                top: mq.padding.top + 10,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page counter pill
                    _Pill(
                      child: Text(
                        '${_currentPage + 1} / ${_slides.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Skip button (hidden on last page)
                    if (_currentPage < _slides.length - 1)
                      GestureDetector(
                        onTap: _finish,
                        child: _Pill(
                          child: Text(
                            isSinhala ? 'මඟ හරින්න' : 'Skip',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Decorative blobs ───────────────────────────────────────────────────────

  Widget _buildBlobs(Size size) {
    return Stack(
      children: [
        Positioned(top: -70, left: -70, child: _Blob(size: 240, opacity: 0.09)),
        Positioned(
          top: size.height * 0.16,
          right: -50,
          child: _Blob(size: 160, opacity: 0.08),
        ),
        Positioned(
          top: size.height * 0.32,
          left: 18,
          child: _Blob(size: 64, opacity: 0.12),
        ),
        Positioned(
          top: size.height * 0.08,
          left: size.width * 0.45,
          child: _Blob(size: 44, opacity: 0.10),
        ),
      ],
    );
  }

  // ── Single slide ───────────────────────────────────────────────────────────

  Widget _buildSlide(_TutorialSlide slide, bool isSinhala, MediaQueryData mq) {
    final botPad = mq.padding.bottom;
    final topPad = mq.padding.top;

    return Column(
      children: [
        // ── Icon area (top portion with gradient showing) ──────
        SizedBox(
          height: mq.size.height * 0.43 + topPad,
          child: Center(
            child: AnimatedBuilder(
              animation: _iconAnim,
              builder: (_, __) => Opacity(
                opacity: _iconFade.value,
                child: Transform.scale(
                  scale: _iconScale.value,
                  child: Container(
                    width: 136,
                    height: 136,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.50),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 36,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(slide.icon, size: 62, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Content card ───────────────────────────────────────
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(26, 26, 26, botPad + 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 32,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tag pill ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: slide.gradient[0].withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: slide.gradient[0].withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    isSinhala ? slide.tagSi : slide.tagEn,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: slide.gradient[0],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Title ────────────────────────────────────────
                Text(
                  isSinhala ? slide.titleSi : slide.titleEn,
                  style: GoogleFonts.poppins(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.18,
                  ),
                ),

                const SizedBox(height: 10),

                // ── Description ──────────────────────────────────
                Text(
                  isSinhala ? slide.descSi : slide.descEn,
                  style: GoogleFonts.roboto(
                    fontSize: 14.5,
                    color: AppColors.textMuted,
                    height: 1.60,
                  ),
                ),

                // ── Feature chips ────────────────────────────────
                if (slide.chips.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slide.chips.map((chip) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: slide.gradient[0].withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: slide.gradient[0].withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(chip.icon, size: 14, color: slide.gradient[0]),
                            const SizedBox(width: 5),
                            Text(
                              isSinhala ? chip.labelSi : chip.labelEn,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: slide.gradient[0],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const Spacer(),

                // ── Progress dots ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                      width: active ? 26 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? slide.gradient[0]
                            : slide.gradient[0].withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // ── CTA button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _completing ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: slide.gradient[0],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: slide.gradient[0].withValues(
                        alpha: 0.55,
                      ),
                      elevation: 6,
                      shadowColor: slide.gradient[0].withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _completing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _slides.length - 1
                                    ? (isSinhala
                                          ? 'ගමන ආරම්භ කරන්න'
                                          : 'Begin My Journey')
                                    : (isSinhala ? 'ඊළඟ' : 'Next'),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage == _slides.length - 1
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tiny reusable widgets ────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final Widget child;
  const _Pill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
      ),
      child: child,
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double opacity;
  const _Blob({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
