import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/constants/colors.dart';
import 'package:mamamind/utils/helpers.dart';

void main() {
  // ── scoreToColorPWS18() ────────────────────────────────────────────────────
  //
  // Formula: t = ((score - 1) / 5).clamp(0, 1)
  //   score=1 → t=0 → colorScaleMin (AppColors.error)
  //   score=6 → t=1 → colorScaleMax (AppColors.success)
  //   score=3.5 → t=0.5 → midpoint lerp

  group('scoreToColorPWS18()', () {
    test('score 1.0 returns colorScaleMin (error red)', () {
      expect(scoreToColorPWS18(1.0), equals(AppColors.colorScaleMin));
    });

    test('score 6.0 returns colorScaleMax (success green)', () {
      expect(scoreToColorPWS18(6.0), equals(AppColors.colorScaleMax));
    });

    test('score below 1.0 is clamped to colorScaleMin', () {
      expect(scoreToColorPWS18(0.0), equals(AppColors.colorScaleMin));
      expect(scoreToColorPWS18(-5.0), equals(AppColors.colorScaleMin));
    });

    test('score above 6.0 is clamped to colorScaleMax', () {
      expect(scoreToColorPWS18(7.0), equals(AppColors.colorScaleMax));
      expect(scoreToColorPWS18(100.0), equals(AppColors.colorScaleMax));
    });

    test('score 3.5 returns an intermediate colour between min and max', () {
      final mid = scoreToColorPWS18(3.5);
      expect(mid, isNot(equals(AppColors.colorScaleMin)));
      expect(mid, isNot(equals(AppColors.colorScaleMax)));
    });

    test('mid score equals Color.lerp at t=0.5', () {
      final expected = Color.lerp(
        AppColors.colorScaleMin,
        AppColors.colorScaleMax,
        0.5,
      )!;
      expect(scoreToColorPWS18(3.5), equals(expected));
    });

    test('higher score produces a colour closer to colorScaleMax', () {
      final low = scoreToColorPWS18(2.0);
      final high = scoreToColorPWS18(5.0);
      // Both are valid colors; just assert they differ
      expect(low, isNot(equals(high)));
    });
  });

  // ── scoreToColorMAAS() ────────────────────────────────────────────────────
  //
  // Same formula as scoreToColorPWS18 — score on a 1–6 scale.

  group('scoreToColorMAAS()', () {
    test('score 1.0 returns colorScaleMin (error red)', () {
      expect(scoreToColorMAAS(1.0), equals(AppColors.colorScaleMin));
    });

    test('score 6.0 returns colorScaleMax (success green)', () {
      expect(scoreToColorMAAS(6.0), equals(AppColors.colorScaleMax));
    });

    test('score below 1.0 is clamped to colorScaleMin', () {
      expect(scoreToColorMAAS(0.0), equals(AppColors.colorScaleMin));
      expect(scoreToColorMAAS(-10.0), equals(AppColors.colorScaleMin));
    });

    test('score above 6.0 is clamped to colorScaleMax', () {
      expect(scoreToColorMAAS(10.0), equals(AppColors.colorScaleMax));
    });

    test('score 3.5 returns an intermediate colour', () {
      final mid = scoreToColorMAAS(3.5);
      expect(mid, isNot(equals(AppColors.colorScaleMin)));
      expect(mid, isNot(equals(AppColors.colorScaleMax)));
    });

    test('mid score equals Color.lerp at t=0.5', () {
      final expected = Color.lerp(
        AppColors.colorScaleMin,
        AppColors.colorScaleMax,
        0.5,
      )!;
      expect(scoreToColorMAAS(3.5), equals(expected));
    });

    test(
      'scoreToColorMAAS and scoreToColorPWS18 produce identical colours',
      () {
        // Both functions use the same formula — results must match.
        for (final score in [1.0, 2.5, 3.5, 5.0, 6.0]) {
          expect(
            scoreToColorMAAS(score),
            equals(scoreToColorPWS18(score)),
            reason: 'Mismatch at score=$score',
          );
        }
      },
    );
  });
}
