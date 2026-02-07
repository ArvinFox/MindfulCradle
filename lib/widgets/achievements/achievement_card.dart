import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../models/achievement_data.dart';

/// Reusable achievement card component
/// Shows individual achievement with icon, title, and description
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final bool isSinhala;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.isUnlocked,
    this.isSinhala = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: isUnlocked
            ? Border.all(color: achievement.color.withOpacity(0.1), width: 1)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? achievement.color.withOpacity(0.15)
                  : Colors.grey[300],
            ),
            child: Icon(
              isUnlocked ? achievement.icon : Icons.lock,
              size: 28,
              color: isUnlocked ? achievement.color : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              isSinhala ? achievement.titleSi : achievement.titleEn,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? AppColors.text : Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              isSinhala ? achievement.descriptionSi : achievement.descriptionEn,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: isUnlocked
                    ? AppColors.text.withOpacity(0.6)
                    : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
