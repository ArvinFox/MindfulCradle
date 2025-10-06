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
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (isLocked) {
          _showLockedFeedback(context);
        } else {
          onTap();
        }
      },
      borderRadius: BorderRadius.circular(16),
      splashColor: AppColors.primary.withOpacity(0.4),
      highlightColor: AppColors.primary.withOpacity(0.15),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_outline_rounded,
                      size: isMobile ? 48 : 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 15 : 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Locked Overlay
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.text.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}