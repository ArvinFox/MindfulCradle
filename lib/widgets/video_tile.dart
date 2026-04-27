import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/language_provider.dart';

// Vivid per-session colour palettes [gradientStart, gradientEnd]
const List<List<Color>> _sessionPalettes = [
  [Color(0xFF6C63FF), Color(0xFF9B88FF)], // violet
  [Color(0xFF1F6F78), Color(0xFF3AA8A3)], // teal (brand)
  [Color(0xFFE06C8B), Color(0xFFF79FC7)], // rose
  [Color(0xFFFF7043), Color(0xFFFFB74D)], // orange
  [Color(0xFF2979FF), Color(0xFF40C4FF)], // blue
  [Color(0xFF43A047), Color(0xFF80E27E)], // green
  [Color(0xFFAB47BC), Color(0xFFE040FB)], // purple
  [Color(0xFFE65100), Color(0xFFFF8F00)], // amber-orange
];

class VideoTile extends StatelessWidget {
  final String title;
  final bool isLocked;
  final bool isMobile;
  final VoidCallback onTap;

  /// 0-based index used to pick the gradient palette
  final int sessionIndex;

  const VideoTile({
    super.key,
    required this.title,
    this.isLocked = false,
    required this.isMobile,
    required this.onTap,
    this.sessionIndex = 0,
  });

  List<Color> get _palette {
    if (isLocked) return const [Color(0xFFCCCCCC), Color(0xFFBBBBBB)];
    return _sessionPalettes[sessionIndex % _sessionPalettes.length];
  }

  void _showLockedFeedback(BuildContext context) {
    final isSinhala =
        Provider.of<LanguageProvider>(context, listen: false).currentLang ==
        'si';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSinhala
              ? 'මෙය අගුළු හැරීමට පෙර සැසිය සම්පූර්ණ කරන්න.'
              : 'Complete the previous session to unlock this one.',
          style: GoogleFonts.roboto(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > constraints.maxHeight * 1.4;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (isLocked) {
              _showLockedFeedback(context);
            } else {
              onTap();
            }
          },
          child: isWide ? _buildWide() : _buildCompact(),
        );
      },
    );
  }

  // ── Compact (square) ───────────────────────────────────────────────────────
  Widget _buildCompact() {
    final palette = _palette;
    return Container(
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFF0F0F0) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked
              ? const Color(0xFFDDDDDD)
              : palette[0].withOpacity(0.22),
          width: 1.2,
        ),
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: palette[0].withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        children: [
          // Gradient thumbnail
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(19),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: palette,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Decorative blobs
                  Positioned(
                    top: -16,
                    right: -16,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -10,
                    left: -10,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Session number badge
                  if (!isLocked)
                    Positioned(
                      top: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.40),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'S${sessionIndex + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Centre play / lock circle
                  Center(
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isLocked ? 0.25 : 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            isLocked ? 0.35 : 0.55,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isLocked
                            ? Icons.lock_outline_rounded
                            : Icons.play_arrow_rounded,
                        size: 24,
                        color: Colors.white.withOpacity(isLocked ? 0.55 : 1.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Title strip
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isLocked
                          ? const Color(0xFFAAAAAA)
                          : AppColors.text,
                      height: 1.25,
                    ),
                  ),
                  if (!isLocked) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tap to play',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: palette[0],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Wide (landscape) ───────────────────────────────────────────────────────
  Widget _buildWide() {
    final palette = _palette;
    return Container(
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFF0F0F0) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked
              ? const Color(0xFFDDDDDD)
              : palette[0].withOpacity(0.22),
          width: 1.2,
        ),
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: palette[0].withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Row(
        children: [
          // Left gradient panel
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(19),
            ),
            child: SizedBox(
              width: 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: palette,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isLocked ? 0.25 : 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            isLocked ? 0.35 : 0.55,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isLocked
                            ? Icons.lock_outline_rounded
                            : Icons.play_arrow_rounded,
                        size: 22,
                        color: Colors.white.withOpacity(isLocked ? 0.55 : 1.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right text area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isLocked) ...[
                    Text(
                      'Session ${sessionIndex + 1}',
                      style: GoogleFonts.roboto(
                        fontSize: 10.5,
                        color: palette[0],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isLocked
                          ? const Color(0xFFAAAAAA)
                          : AppColors.text,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isLocked
                            ? Icons.lock_outline_rounded
                            : Icons.play_circle_outline_rounded,
                        size: 13,
                        color: isLocked ? const Color(0xFFAAAAAA) : palette[0],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLocked ? 'Locked' : 'Tap to play',
                        style: GoogleFonts.roboto(
                          fontSize: 11.5,
                          color: isLocked
                              ? const Color(0xFFAAAAAA)
                              : palette[0],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
