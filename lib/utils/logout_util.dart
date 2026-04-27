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
        final width = MediaQuery.of(ctx).size.width;
        final compact = width < 380;

        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width < 720 ? width - 24 : 520,
            ),
            child: Container(
              padding: EdgeInsets.all(compact ? 16 : 24),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: compact ? 44 : 50,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: compact ? 14 : 20),

                  Text(
                    language == 'en'
                        ? "Logout Confirmation"
                        : "පිටවීම තහවුරු කිරීම",
                    style: GoogleFonts.poppins(
                      fontSize: compact ? 18 : 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Content Text
                  Text(
                    language == 'en'
                        ? "Are you sure you want to log out?"
                        : "ඔබට පිටවීමට කැමතිද?",
                    style: GoogleFonts.roboto(
                      fontSize: compact ? 14 : 16,
                      color: AppColors.text.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: compact ? 18 : 28),

                  // Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.text.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: AppColors.text,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              vertical: compact ? 13 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            language == 'en' ? "Cancel" : "අවලංගු කරන්න",
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                            ),
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
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              vertical: compact ? 13 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            language == 'en' ? "Yes, Logout" : "ඔව්, පිටවෙන්න",
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
