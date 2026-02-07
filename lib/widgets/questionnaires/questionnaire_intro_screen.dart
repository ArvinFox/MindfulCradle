import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

/// Reusable intro screen widget for questionnaires
/// Shows a welcome message and start button
class QuestionnaireIntroScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onStart;
  final bool isMobile;

  const QuestionnaireIntroScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onStart,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 20 : 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w400,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onStart,
                child: Text(
                  buttonText,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.buttonText,
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
