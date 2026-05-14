import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Wraps any Scaffold body with the app-wide background.
/// Attempts to load the PNG background image first; falls back to the
/// soothing gradient + ambient blobs if the asset is missing or corrupt.
/// Set [useGradient] to true to always use the gradient+blobs background
/// (skips PNG — use this on pages where the PNG interferes with readability).
/// Usage:
///   body: AppBackground(child: yourExistingBodyWidget)
///   body: AppBackground(useGradient: true, child: yourExistingBodyWidget)
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool useGradient;

  /// How opaque the white overlay is over the PNG background.
  /// 0.0 = fully transparent (no fade), 1.0 = solid white.
  /// 0.50 = 50% fade (default), 0.85 = heavy fade for chat page.
  final double overlayOpacity;

  /// Custom asset path for the background PNG.
  /// Defaults to the main background. Pass a different path to use another image.
  final String? imagePath;

  const AppBackground({
    super.key,
    required this.child,
    this.useGradient = false,
    this.overlayOpacity = 0.50,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    if (useGradient) {
      // Plain gradient + ambient blobs — no PNG, no overlay
      return Stack(
        children: [
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8F5F2), Color(0xFFF4F0EC)],
                ),
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.heroGradientMid.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      );
    }

    return Stack(
      children: [
        // PNG background — full cover, falls back to gradient+blobs on error
        Positioned.fill(
          child: Image.asset(
            imagePath ?? 'assets/main/Mindful_Cradle_Main_Background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback: soothing gradient + ambient blobs
              return Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFF8F5F2), Color(0xFFF4F0EC)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -60,
                    right: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.heroGradientMid.withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 150,
                    left: -50,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        // Faded white overlay — keeps PNG subtle so it doesn't overpower UI
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: overlayOpacity),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
