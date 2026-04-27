import 'package:flutter/material.dart';

class AppColors {
  // Brand and primary palette — sage green for calm, nature, wellness
  static const Color primary = Color(0xFF5A7F72);
  static const Color primaryLight = Color(0xFF7CA698);
  static const Color primaryDark = Color(0xFF3D5F52);

  // Accent — dusty peach, evoking warmth and nurturing for maternal context
  static const Color accent = Color(0xFFD4856A);

  // Soft peachy blush — used for highlights and special UI moments
  static const Color rose = Color(0xFFE8B09A);

  // Surface and text palette — warm ivory tones
  static const Color background = Color(0xFFFBF8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2EDE8);
  static const Color text = Color(0xFF1F2933);
  static const Color textMuted = Color(0xFF52606D);
  static const Color border = Color(0xFFD6CFC8);

  // Feedback colors — used in UI indicators
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

  // Home screen hero gradient — sage to light sage
  static const Color heroGradientStart = Color(0xFF4E7A6A);
  static const Color heroGradientMid = Color(0xFF5E8C7B);
  static const Color heroGradientEnd = Color(0xFFA8C8BE);
  static const Color progressTrack = Color(0xFFDCE8E4);
  static const Color progressValue = Color(0xFFD4856A);

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
