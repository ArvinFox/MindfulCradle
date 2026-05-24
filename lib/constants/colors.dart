import 'package:flutter/material.dart';

class AppColors {
  // Brand and primary palette lavender-purple from the app logo
  static const Color primary = Color(0xFF7B5AA8);
  static const Color primaryLight = Color(0xFF9B7DC4);
  static const Color primaryDark = Color(0xFF5A3F88);

  // Accent periwinkle blue from the logo's headphones
  static const Color accent = Color(0xFF6BAED0);

  // Soft lavender used for highlights and special UI moments
  static const Color rose = Color(0xFFC9A8E0);

  // Surface and text palette warm lavender-tinted ivory tones
  static const Color background = Color(0xFFFAF8FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2EAF9);
  static const Color text = Color(0xFF1F2033);
  static const Color textMuted = Color(0xFF5A5272);
  static const Color border = Color(0xFFD8CEE8);

  // Feedback colors used in UI indicators
  static const Color success = Color(0xFF2D7D5E);
  static const Color warning = Color(0xFFE28E28);
  static const Color error = Color(0xFFCF4D4D);
  static const Color info = Color(0xFF2B7CD3);

  // Toast / SnackBar semantic background colors (rich, accessible contrast)
  static const Color snackSuccess = Color(0xFF1E5E42);
  static const Color snackError = Color(0xFFB03020);
  static const Color snackWarning = Color(0xFF8A5520);
  static const Color snackInfo = Color(0xFF1A5290);
  static const Color snackNeutral = Color(0xFF2D3748);

  // Home screen hero gradient — deep lavender to soft lavender
  static const Color heroGradientStart = Color(0xFF6A48A0);
  static const Color heroGradientMid = Color(0xFF7D5EB8);
  static const Color heroGradientEnd = Color(0xFFC4ACD8);
  static const Color progressTrack = Color(0xFFE4D8F4);
  static const Color progressValue = Color(0xFF6BAED0);

  static const List<Color> sessionAccentPalette = [
    Color(0xFF2B7CD3),
    Color(0xFF2D9D78),
    Color(0xFFE28E28),
    Color(0xFF8C6AD8),
    Color(0xFF3E9CB3),
    Color(0xFFD16167),
  ];

  // Backward-compatible aliases used across existing screens
  static const Color inputBackground = surface;
  static const Color buttonText = Colors.white;
  static const Color titleBarText = Colors.white;
  static const Color buttonPrevBack = Color(0xFFB9B9B9);
  static const Color cardBackground = surface;
  static const Color completed = success;
  static const Color tileInactive = Color(0xFFB9B9B9);
  static const Color colorScaleMin = error;
  static const Color colorScaleMax = success;
}
