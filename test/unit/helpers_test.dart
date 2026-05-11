import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/utils/helpers.dart';
import 'package:mamamind/constants/colors.dart';

void main() {
  // ── formatDuration() ───────────────────────────────────────────────────
  group('formatDuration()', () {
    test('0 seconds → "00:00"', () {
      expect(formatDuration(0), '00:00');
    });

    test('1 second → "00:01"', () {
      expect(formatDuration(1), '00:01');
    });

    test('59 seconds → "00:59"', () {
      expect(formatDuration(59), '00:59');
    });

    test('60 seconds (1 min) → "01:00"', () {
      expect(formatDuration(60), '01:00');
    });

    test('65 seconds → "01:05"', () {
      expect(formatDuration(65), '01:05');
    });

    test('3600 seconds (60 min) → "60:00"', () {
      expect(formatDuration(3600), '60:00');
    });

    test('3661 seconds → "61:01"', () {
      expect(formatDuration(3661), '61:01');
    });
  });

  // ── formatDate() ────────────────────────────────────────────────────────
  group('formatDate()', () {
    test('formats date as "day/month/year"', () {
      expect(formatDate(DateTime(2024, 1, 5)), '5/1/2024');
    });

    test('formats two-digit day and month without leading zeros', () {
      expect(formatDate(DateTime(2024, 12, 31)), '31/12/2024');
    });

    test('formats correctly for single-digit day and month', () {
      expect(formatDate(DateTime(2025, 3, 7)), '7/3/2025');
    });

    test('formats start of year', () {
      expect(formatDate(DateTime(2023, 1, 1)), '1/1/2023');
    });
  });

  // ── scoreToColorDASS21() ─────────────────────────────────────────────────
  group('scoreToColorDASS21()', () {
    // ── Depression (EN) ──────────────────────────────────────────────────
    group('depression (English)', () {
      test('score 9 → colorScaleMax (normal)', () {
        expect(scoreToColorDASS21('depression', 9), AppColors.colorScaleMax);
      });

      test('score 10 → lightGreen (mild)', () {
        expect(scoreToColorDASS21('depression', 10), Colors.lightGreen);
      });

      test('score 13 → lightGreen (mild boundary)', () {
        expect(scoreToColorDASS21('depression', 13), Colors.lightGreen);
      });

      test('score 14 → orange (moderate)', () {
        expect(scoreToColorDASS21('depression', 14), Colors.orange);
      });

      test('score 20 → orange (moderate boundary)', () {
        expect(scoreToColorDASS21('depression', 20), Colors.orange);
      });

      test('score 21 → deepOrange (severe)', () {
        expect(scoreToColorDASS21('depression', 21), Colors.deepOrange);
      });

      test('score 27 → deepOrange (severe boundary)', () {
        expect(scoreToColorDASS21('depression', 27), Colors.deepOrange);
      });

      test('score 28 → colorScaleMin (extremely severe)', () {
        expect(scoreToColorDASS21('depression', 28), AppColors.colorScaleMin);
      });
    });

    // ── Depression (SI) ──────────────────────────────────────────────────
    group('depression (Sinhala subscale name)', () {
      test('Sinhala subscale name maps to the same colour as English', () {
        for (int s in [0, 9, 13, 20, 27, 42]) {
          expect(
            scoreToColorDASS21('මානසික අවපීඩනය', s),
            scoreToColorDASS21('depression', s),
            reason: 'Mismatch at score $s',
          );
        }
      });
    });

    // ── Anxiety (EN) ─────────────────────────────────────────────────────
    group('anxiety (English)', () {
      test('score 7 → colorScaleMax (normal)', () {
        expect(scoreToColorDASS21('anxiety', 7), AppColors.colorScaleMax);
      });

      test('score 8 → lightGreen (mild)', () {
        expect(scoreToColorDASS21('anxiety', 8), Colors.lightGreen);
      });

      test('score 9 → lightGreen (mild boundary)', () {
        expect(scoreToColorDASS21('anxiety', 9), Colors.lightGreen);
      });

      test('score 10 → orange (moderate)', () {
        expect(scoreToColorDASS21('anxiety', 10), Colors.orange);
      });

      test('score 14 → orange (moderate boundary)', () {
        expect(scoreToColorDASS21('anxiety', 14), Colors.orange);
      });

      test('score 15 → deepOrange (severe)', () {
        expect(scoreToColorDASS21('anxiety', 15), Colors.deepOrange);
      });

      test('score 19 → deepOrange (severe boundary)', () {
        expect(scoreToColorDASS21('anxiety', 19), Colors.deepOrange);
      });

      test('score 20 → colorScaleMin (extremely severe)', () {
        expect(scoreToColorDASS21('anxiety', 20), AppColors.colorScaleMin);
      });
    });

    // ── Anxiety (SI) ─────────────────────────────────────────────────────
    group('anxiety (Sinhala subscale name)', () {
      test('Sinhala "කාංසාව" maps identically to "anxiety"', () {
        for (int s in [7, 9, 14, 19, 42]) {
          expect(
            scoreToColorDASS21('කාංසාව', s),
            scoreToColorDASS21('anxiety', s),
          );
        }
      });
    });

    // ── Stress (EN) ──────────────────────────────────────────────────────
    group('stress (English)', () {
      test('score 14 → colorScaleMax (normal)', () {
        expect(scoreToColorDASS21('stress', 14), AppColors.colorScaleMax);
      });

      test('score 15 → lightGreen (mild)', () {
        expect(scoreToColorDASS21('stress', 15), Colors.lightGreen);
      });

      test('score 18 → lightGreen (mild boundary)', () {
        expect(scoreToColorDASS21('stress', 18), Colors.lightGreen);
      });

      test('score 19 → orange (moderate)', () {
        expect(scoreToColorDASS21('stress', 19), Colors.orange);
      });

      test('score 25 → orange (moderate boundary)', () {
        expect(scoreToColorDASS21('stress', 25), Colors.orange);
      });

      test('score 26 → deepOrange (severe)', () {
        expect(scoreToColorDASS21('stress', 26), Colors.deepOrange);
      });

      test('score 33 → deepOrange (severe boundary)', () {
        expect(scoreToColorDASS21('stress', 33), Colors.deepOrange);
      });

      test('score 34 → colorScaleMin (extremely severe)', () {
        expect(scoreToColorDASS21('stress', 34), AppColors.colorScaleMin);
      });
    });

    // ── Stress (SI) ──────────────────────────────────────────────────────
    group('stress (Sinhala subscale name)', () {
      test('Sinhala "පීඩනය" maps identically to "stress"', () {
        for (int s in [14, 18, 25, 33, 42]) {
          expect(
            scoreToColorDASS21('පීඩනය', s),
            scoreToColorDASS21('stress', s),
          );
        }
      });
    });

    // ── Unknown subscale ─────────────────────────────────────────────────
    group('unknown subscale', () {
      test('returns tileInactive color', () {
        expect(scoreToColorDASS21('unknown', 10), AppColors.tileInactive);
      });
    });
  });

  // ── scoreToColorPWS18() / scoreToColorMAAS() ─────────────────────────────
  group('scoreToColorPWS18() and scoreToColorMAAS()', () {
    test('score 1.0 → colorScaleMin (t=0)', () {
      // t = (1-1)/5 = 0 → lerp(min, max, 0) = min
      expect(scoreToColorPWS18(1.0), AppColors.colorScaleMin);
      expect(scoreToColorMAAS(1.0), AppColors.colorScaleMin);
    });

    test('score 6.0 → colorScaleMax (t=1)', () {
      // t = (6-1)/5 = 1 → lerp(min, max, 1) = max
      expect(scoreToColorPWS18(6.0), AppColors.colorScaleMax);
      expect(scoreToColorMAAS(6.0), AppColors.colorScaleMax);
    });

    test('score below 1 clamps to colorScaleMin', () {
      expect(scoreToColorPWS18(0.0), AppColors.colorScaleMin);
      expect(scoreToColorMAAS(0.0), AppColors.colorScaleMin);
    });

    test('score above 6 clamps to colorScaleMax', () {
      expect(scoreToColorPWS18(10.0), AppColors.colorScaleMax);
      expect(scoreToColorMAAS(10.0), AppColors.colorScaleMax);
    });

    test('both functions return the same color for the same score', () {
      for (final score in [1.0, 2.0, 3.5, 6.0]) {
        expect(
          scoreToColorPWS18(score),
          scoreToColorMAAS(score),
          reason: 'Mismatch at score $score',
        );
      }
    });
  });
}
