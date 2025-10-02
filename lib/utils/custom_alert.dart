// utils/custom_confirmation_dialog.dart
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CustomConfirmationDialog {
  /// Shows a modern confirmation dialog like the logout dialog.
  /// Returns true if confirmed, false if canceled.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = "Yes",
    String cancelText = "No",
    bool isDestructive = false, // optional red confirm
    IconData? icon,             // optional icon on top
    Color? iconColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isMobile = MediaQuery.of(ctx).size.width < 600;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(icon,
                      size: 50, color: iconColor ?? AppColors.primary.withOpacity(0.8)),
                if (icon != null) const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(fontSize: isMobile ? 16 : 18, color: AppColors.text),
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
                        child: Text(cancelText),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive ? Colors.red : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(confirmText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }
}
