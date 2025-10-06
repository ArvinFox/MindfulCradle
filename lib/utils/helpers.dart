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
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 2,
      ), 
    ),
    
    // Error state
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(
        color: Colors.red,
        width: 2,
      ), 
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