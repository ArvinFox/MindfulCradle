import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mamamind/constants/colors.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../models/achievement_data.dart';
import '../providers/language_provider.dart';
import '../utils/globals.dart';

class AchievementProvider with ChangeNotifier {
  final List<Achievement> _pendingBadges = [];

  Future<void> unlockAchievement(
    BuildContext context,
    String achievementId, {
    bool showUI = true,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    // Check if already unlocked
    if (user.achievements.contains(achievementId)) {
      return;
    }

    try {
      // Update Firebase
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'achievements': FieldValue.arrayUnion([achievementId]),
      });

      // Update Local State
      authProvider.addLocalAchievement(achievementId);

      // Handle UI
      final badge = AchievementData.findById(achievementId);

      if (badge != null) {
        if (showUI) {
          await Future.delayed(const Duration(milliseconds: 300));
          final globalContext = navigatorKey.currentContext;
          if (globalContext != null) {
            _showUnlockDialog(globalContext, badge);
          }
        } else {
          _pendingBadges.add(badge);
        }
      }

      // Check for "Super Mom"
      const requiredBadges = [
        'first_step',
        'halfway_there',
        'zen_master',
        'self_aware',
        'mindful_observer',
        'happiness_seeker',
      ];

      final currentBadges = authProvider.user?.achievements ?? [];
      final hasAll = requiredBadges.every((id) => currentBadges.contains(id));

      if (hasAll && !currentBadges.contains('super_mom')) {
        await unlockAchievement(context, 'super_mom', showUI: showUI);
      }
    } catch (e) {
      debugPrint("Error unlocking achievement: $e");
    }
  }

  void showPendingAchievements(BuildContext context) async {
    if (_pendingBadges.isEmpty) return;
    for (final badge in List.from(_pendingBadges)) {
      if (context.mounted) {
        await _showUnlockDialog(context, badge);
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
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 700),

      // Dialog Content
      pageBuilder: (ctx, anim1, anim2) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: badge.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(badge.icon, size: 48, color: badge.color),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  isSinhala ? "සුබ පැතුම්!" : "Congratulations!",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),

                // Badge Name
                Text(
                  isSinhala ? badge.titleSi : badge.titleEn,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  isSinhala
                      ? "ඔබ නව ජයග්‍රහණයක් අත්කර ගෙන ඇත."
                      : "You've unlocked a new badge!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: badge.color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isSinhala ? "නියමයි!" : "Awesome!",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOut.transform(anim1.value);

        return Transform.scale(
          scale: 0.8 + (0.2 * curvedValue),
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
    );
  }
}
