import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

/// A reusable widget to display a single achievement or badge.
class AchievementTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isCompleted;

  const AchievementTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.star,
    this.iconColor = Colors.amber,
    this.isCompleted = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final cardColor = isCompleted 
        ? AppColors.cardBackground
        : AppColors.cardBackground.withOpacity(0.8);

    final titleColor = isCompleted ? AppColors.text : AppColors.text.withOpacity(0.5);
    final shadowColor = isCompleted 
        ? Colors.black.withOpacity(0.1) 
        : Colors.black.withOpacity(0.05);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted ? null : Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 36,
            color: isCompleted ? iconColor : Colors.grey.shade400,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with Poppins font
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                // Subtitle / description with Roboto font
                if (subtitle != null && isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      subtitle!,
                      style: GoogleFonts.roboto(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.text.withOpacity(0.7),
                      ),
                    ),
                  ),
                // Locked text
                if (!isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Locked",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.red.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isCompleted)
            Icon(Icons.check_circle_outline, color: AppColors.completed),
        ],
      ),
    );
  }
}
