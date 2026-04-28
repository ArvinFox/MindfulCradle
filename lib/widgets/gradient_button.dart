import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// A primary action button with the app's signature lavender-purple gradient.
///
/// Wraps an [ElevatedButton] inside a [DecoratedBox] that applies a
/// [LinearGradient] from [AppColors.primaryDark] to [AppColors.primaryLight].
/// The inner button uses `Colors.transparent` so only the gradient shows.
///
/// Usage — drop-in replacement for a flat primary ElevatedButton:
/// ```dart
/// GradientButton(
///   onPressed: _handleTap,
///   child: Text('Continue'),
/// )
/// ```
///
/// Supports icon variants via [GradientButton.icon].
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double elevation;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.elevation = 0,
  });

  /// Icon variant — mirrors [ElevatedButton.icon] with the gradient style.
  static Widget icon({
    Key? key,
    required VoidCallback? onPressed,
    required Widget icon,
    required Widget label,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 14,
      horizontal: 16,
    ),
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(14)),
  }) {
    return GradientButton(
      key: key,
      onPressed: onPressed,
      padding: padding,
      borderRadius: borderRadius,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [icon, const SizedBox(width: 8), label],
      ),
    );
  }

  static const _gradient = LinearGradient(
    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed != null ? _gradient : null,
        color: onPressed != null ? null : Colors.grey.shade300,
        borderRadius: borderRadius,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.grey.shade600,
          shadowColor: Colors.transparent,
          elevation: elevation,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        child: child,
      ),
    );
  }
}
