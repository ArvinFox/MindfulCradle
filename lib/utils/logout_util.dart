// utils/logout_utils.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';

class LogoutUtils {
  static Future<void> showLogoutDialog({
    required BuildContext context,
    required AuthProvider authProvider,
    required String language,
    String? redirectRoute,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {

        return Dialog(
          backgroundColor: AppColors.background.withOpacity(0.95),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout_rounded,
                    size: 50, color: AppColors.primary),
                const SizedBox(height: 20),

                Text(
                  language == 'en'
                      ? "Logout Confirmation"
                      : "පිටවීම තහවුරු කිරීම",
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text),
                ),
                const SizedBox(height: 12),
                
                // Content Text
                Text(
                  language == 'en'
                      ? "Are you sure you want to log out?"
                      : "ඔබට පිටවීමට කැමතිද?",
                  style: GoogleFonts.roboto(fontSize: 16, color: AppColors.text.withOpacity(0.8)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.text.withOpacity(0.1),
                          foregroundColor: AppColors.text,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          language == 'en' ? "Cancel" : "අවලංගු කරන්න",
                          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Yes Button (Primary Action)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          language == 'en' ? "Yes, Logout" : "ඔව්, පිටවෙන්න",
                          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );

    if (confirmed ?? false) {
      await authProvider.logout();
      if (redirectRoute != null && context.mounted) {
        Navigator.pushReplacementNamed(context, redirectRoute);
      }
    }
  }
}