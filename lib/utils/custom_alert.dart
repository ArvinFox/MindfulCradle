import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class CustomConfirmationDialog {

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = "Yes",
    String cancelText = "No",
    bool isDestructive = false,
    IconData? icon,
    Color? iconColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.text.withOpacity(0.30), 
      barrierDismissible: false,
      builder: (ctx) {
        final isMobile = MediaQuery.of(ctx).size.width < 600;
        return Dialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.98),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.text.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(icon,
                      size: 50, color: iconColor ?? AppColors.primary),
                if (icon != null) const SizedBox(height: 16),
                
                // Title Text
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 20 : 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Message Text
                Text(
                  message,
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 16 : 18, 
                    color: AppColors.text.withOpacity(0.8)
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Buttons Row
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          cancelText,
                          style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Confirm Button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive ? Colors.red.shade700 : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          confirmText,
                          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                        ),
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