import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/language_provider.dart';

class VideoTile extends StatelessWidget {
  final String title;
  final bool isLocked;
  final bool isMobile;
  final VoidCallback onTap;

  const VideoTile({
    super.key,
    required this.title,
    this.isLocked = false,
    required this.isMobile,
    required this.onTap,
  });

  void _showLockedFeedback(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isSinhala = langProvider.currentLang == 'si';

    final String message = isSinhala
        ? "මෙය අගුළු හැරීමට පෙර සැසිය සම්පූර්ණ කරන්න."
        : "Complete the previous session to unlock this one.";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
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
    // Style matches Achievement Card exactly
    final backgroundColor = isLocked
        ? const Color(0xFFF0F0F0)
        : AppColors.cardBackground;
    final iconBgColor = isLocked
        ? Colors.grey[300]
        : AppColors.primary.withOpacity(0.1);
    final iconColor = isLocked ? Colors.grey[500] : AppColors.primary;
    final textColor = isLocked ? Colors.grey[500] : AppColors.text;
    final shadowColor = isLocked
        ? Colors.transparent
        : Colors.black.withOpacity(0.05);

    return InkWell(
      onTap: () {
        if (isLocked) {
          _showLockedFeedback(context);
        } else {
          onTap();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          // Add a subtle border for unlocked items to make them pop
          border: isLocked
              ? null
              : Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Icon Circle ---
            Container(
              width: isMobile ? 50 : 60,
              height: isMobile ? 50 : 60,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLocked ? Icons.lock : Icons.play_arrow_rounded,
                size: isMobile ? 28 : 32,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 12),

            // --- Title ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 13 : 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
