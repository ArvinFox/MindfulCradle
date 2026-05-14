import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class AppSnackBar {
  AppSnackBar._();

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    message: message,
    bgColor: AppColors.snackSuccess,
    icon: Icons.check_circle_outline_rounded,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    message: message,
    bgColor: AppColors.snackError,
    icon: Icons.error_outline_rounded,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    message: message,
    bgColor: AppColors.snackWarning,
    icon: Icons.warning_amber_rounded,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    message: message,
    bgColor: AppColors.snackInfo,
    icon: Icons.info_outline_rounded,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void neutral(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    message: message,
    bgColor: AppColors.snackNeutral,
    icon: null,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  // Private builder

  static void _show(
    BuildContext context, {
    required String message,
    required Color bgColor,
    required IconData? icon,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: duration,
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white.withValues(alpha: 0.85),
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }
}
