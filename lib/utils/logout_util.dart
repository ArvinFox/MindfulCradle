// utils/logout_utils.dart
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';

class LogoutUtils {
  static Future<void> showLogoutDialog({
    required BuildContext context,
    required AuthProvider authProvider,
    required String language, // 'en' or 'si'
    String? redirectRoute,    // e.g., '/login'
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout,
                    size: 50, color: AppColors.primary.withOpacity(0.8)),
                const SizedBox(height: 16),
                Text(
                  language == 'en'
                      ? "Logout Confirmation"
                      : "පිටවීම තහවුරු කිරීම",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text),
                ),
                const SizedBox(height: 12),
                Text(
                  language == 'en'
                      ? "Are you sure you want to logout?"
                      : "ඔබට පිටවීමට කැමතිද?",
                  style: TextStyle(fontSize: 16, color: AppColors.text),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(language == 'en' ? "Cancel" : "අවලංගු කරන්න"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(language == 'en' ? "Yes" : "ඔව්"),
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
