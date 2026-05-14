import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mamamind/constants/colors.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../models/achievement_data.dart';
import '../providers/language_provider.dart';
import '../services/achievement_service.dart';
import '../utils/globals.dart';

class AchievementProvider with ChangeNotifier {
  final AchievementService _achievementService = AchievementService();
  final List<Achievement> _pendingBadges = [];

  Future<void> unlockAchievement(
    BuildContext context,
    String achievementId, {
    bool showUI = true,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    try {
      final unlockedIds = await _achievementService.unlockAchievement(
        userId: user.id,
        currentAchievements: user.achievements,
        achievementId: achievementId,
      );

      if (unlockedIds.isEmpty) return;

      for (final id in unlockedIds) {
        authProvider.addLocalAchievement(id);
        final badge = AchievementData.findById(id);

        if (badge != null) {
          if (showUI) {
            await Future.delayed(const Duration(milliseconds: 300));
            final globalContext = navigatorKey.currentContext ?? context;
            await _showUnlockDialog(globalContext, badge);
          } else {
            _pendingBadges.add(badge);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error unlocking achievement.");
    }
  }

  Future<void> showPendingAchievements(BuildContext context) async {
    if (_pendingBadges.isEmpty) return;
    // Use the global navigator context so this works even after the calling
    // page has been popped (e.g. questionnaire screens pop before calling this)
    final showCtx = navigatorKey.currentContext ?? context;
    for (final badge in List.from(_pendingBadges)) {
      if (showCtx.mounted) {
        await _showUnlockDialog(showCtx, badge);
      }
    }
    _pendingBadges.clear();
  }

  // Internal Dialog Logic
  Future<void> _showUnlockDialog(
    BuildContext context,
    Achievement badge,
  ) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isSinhala = langProvider.currentLang == 'si';

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Achievement Unlocked",
      barrierColor: Colors.black.withOpacity(0.60),
      transitionDuration: const Duration(milliseconds: 500),

      // Dialog Content
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: badge.color.withOpacity(0.30),
                      blurRadius: 40,
                      spreadRadius: 2,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gradient header with icon
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [badge.color.withOpacity(0.85), badge.color],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Star accent row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.white.withOpacity(0.60),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isSinhala
                                    ? 'ජයග්‍රහණය!'
                                    : 'Achievement Unlocked!',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.92),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.star_rounded,
                                color: Colors.white.withOpacity(0.60),
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Glowing icon circle
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.55),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.30),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              badge.icon,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                      child: Column(
                        children: [
                          // Congratulations subtitle
                          Text(
                            isSinhala ? "සුභ පැතුම්!" : "Congratulations!",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: badge.color,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Badge name
                          Text(
                            isSinhala ? badge.titleSi : badge.titleEn,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Divider(color: Colors.grey.shade100, thickness: 1.5),
                          const SizedBox(height: 12),

                          // Badge description
                          Text(
                            isSinhala
                                ? badge.descriptionSi
                                : badge.descriptionEn,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              height: 1.6,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Awesome button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: badge.color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: badge.color.withOpacity(0.45),
                              ),
                              child: Text(
                                isSinhala ? "නියමයි!" : "Awesome!",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
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
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final bounceValue = Curves.elasticOut.transform(
          anim1.value.clamp(0.0, 1.0),
        );
        return Transform.scale(
          scale: 0.5 + (0.5 * bounceValue),
          child: Opacity(
            opacity: (anim1.value * 2).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }
}
