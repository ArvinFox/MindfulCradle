import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

InputDecoration customInputDecoration(String labelText) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: GoogleFonts.roboto(
      color: AppColors.text.withOpacity(0.7),
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: AppColors.inputBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),

    // Default border
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),

    // Focused state
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),

    // Error state
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  );
}

// Formats seconds into mm:ss
String formatDuration(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

Color scoreToColorPWS18(double score) {
  double t = ((score - 1) / 5).clamp(0.0, 1.0);
  return Color.lerp(AppColors.colorScaleMin, AppColors.colorScaleMax, t)!;
}

Color scoreToColorMAAS(double score) {
  double t = ((score - 1) / 5).clamp(0.0, 1.0);
  return Color.lerp(AppColors.colorScaleMin, AppColors.colorScaleMax, t)!;
}

Color scoreToColorDASS21(String subscale, int score) {
  final lower = subscale.toLowerCase();

  switch (lower) {
    case 'depression':
    case 'මානසික අවපීඩනය':
      if (score <= 9) return Colors.green;
      if (score <= 13) return Colors.lightGreen;
      if (score <= 20) return Colors.orange;
      if (score <= 27) return Colors.deepOrange;
      return Colors.red;

    case 'anxiety':
    case 'කාංසාව':
      if (score <= 7) return Colors.green;
      if (score <= 9) return Colors.lightGreen;
      if (score <= 14) return Colors.orange;
      if (score <= 19) return Colors.deepOrange;
      return Colors.red;

    case 'stress':
    case 'පීඩනය':
      if (score <= 14) return Colors.green;
      if (score <= 18) return Colors.lightGreen;
      if (score <= 25) return Colors.orange;
      if (score <= 33) return Colors.deepOrange;
      return Colors.red;

    default:
      return AppColors.tileInactive;
  }
}

final appBarTextStyle = GoogleFonts.poppins(
  color: AppColors.titleBarText,
  fontWeight: FontWeight.w600,
  fontSize: 20,
);

final selectedLabelStyle = GoogleFonts.poppins(
  color: AppColors.titleBarText,
  fontWeight: FontWeight.w500,
  fontSize: 12,
);

final unselectedLabelStyle = GoogleFonts.poppins(
  color: AppColors.titleBarText,
  fontWeight: FontWeight.w400,
  fontSize: 12,
);

final primaryColorTitleStyle = GoogleFonts.poppins(
  color: AppColors.primary,
  fontWeight: FontWeight.w600,
  fontSize: 20,
);
