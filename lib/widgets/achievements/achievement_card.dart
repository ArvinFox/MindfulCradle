import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../models/achievement_data.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final bool isSinhala;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.isUnlocked,
    this.isSinhala = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isUnlocked) {
      return _UnlockedCard(
        achievement: achievement,
        isSinhala: isSinhala,
        onTap: onTap,
      );
    }
    return _LockedCard(achievement: achievement, isSinhala: isSinhala);
  }
}

// ── Unlocked: vivid gradient card ─────────────────────────────────────────────
class _UnlockedCard extends StatelessWidget {
  final Achievement achievement;
  final bool isSinhala;
  final VoidCallback? onTap;

  const _UnlockedCard({
    required this.achievement,
    required this.isSinhala,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = achievement.color;
    // Derive a slightly lighter/desaturated tint for the gradient end
    final cLight = Color.lerp(c, Colors.white, 0.28)!;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [c, cLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: c.withOpacity(0.42),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Decorative circle – top right
            Positioned(
              top: -18,
              right: -18,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Decorative circle – bottom left
            Positioned(
              bottom: -14,
              left: -14,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon circle with glowing white ring
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.55),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.30),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      achievement.icon,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSinhala ? achievement.titleSi : achievement.titleEn,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      isSinhala
                          ? achievement.descriptionSi
                          : achievement.descriptionEn,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // "Earned" pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.45),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: Colors.white.withOpacity(0.92),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSinhala ? 'ලැබිණි' : 'Earned',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Locked: greyscale frosted card ────────────────────────────────────────────
class _LockedCard extends StatelessWidget {
  final Achievement achievement;
  final bool isSinhala;

  const _LockedCard({required this.achievement, required this.isSinhala});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBE0E3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Color(0xFFD8ECF0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 28,
                color: Color(0xFF7AABB2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isSinhala ? achievement.titleSi : achievement.titleEn,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withOpacity(0.80),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                isSinhala
                    ? achievement.descriptionSi
                    : achievement.descriptionEn,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.primary.withOpacity(0.65),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDEF0F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: Color(0xFF7AABB2),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSinhala ? 'අගුළු' : 'Locked',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7AABB2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
