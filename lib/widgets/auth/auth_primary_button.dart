import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double fontSize;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.fontSize,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.buttonText,
          minimumSize: const Size.fromHeight(52),
          padding: EdgeInsets.symmetric(vertical: compact ? 14 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: compact ? (fontSize - 1) : fontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.buttonText,
                ),
              ),
      ),
    );
  }
}
