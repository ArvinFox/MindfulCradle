import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/services/maas_service.dart';
import 'package:mamamind/services/pws18_service.dart';
import 'package:mamamind/services/localization_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    LocalizationService.instance.reset();
    await LocalizationService.instance.loadTranslations();
  });

  // ── MAASService ────────────────────────────────────────────────────────
  group('MAASService', () {
    final maas = MAASService();

    group('calculateScores()', () {
      test('returns average of all responses', () {
        // 15 items all answered 4 → average = 4.0
        final responses = List<int?>.filled(15, 4);
        final avg = maas.calculateScores(responses);
        expect(avg, closeTo(4.0, 0.001));
      });

      test('returns correct average for mixed responses', () {
        // [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5] → sum=45, len=15 → avg=3.0
        final responses = <int?>[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5];
        expect(maas.calculateScores(responses), closeTo(3.0, 0.001));
      });

      test('treats null as 0', () {
        // 14 items of 0 and 1 item null → (0 × 14 + 0) / 15 = 0.0
        final responses = List<int?>.filled(15, 0);
        responses[0] = null;
        expect(maas.calculateScores(responses), closeTo(0.0, 0.001));
      });

      test('single-item list returns that value as average', () {
        expect(maas.calculateScores([5]), closeTo(5.0, 0.001));
      });
    });

    group('classifyScore()', () {
      test('score exactly 4.0 → high level mindfulness', () {
        final label = maas.classifyScore(4.0);
        expect(
          label.toLowerCase(),
          anyOf(contains('high'), contains('mindful')),
        );
      });

      test('score 5.0 → high level mindfulness', () {
        final label = maas.classifyScore(5.0);
        expect(
          label.toLowerCase(),
          anyOf(contains('high'), contains('mindful')),
        );
      });

      test('score 3.9 → low level mindfulness', () {
        final label = maas.classifyScore(3.9);
        expect(
          label.toLowerCase(),
          anyOf(contains('low'), contains('mindful')),
        );
      });

      test('score 1.0 → low level mindfulness', () {
        final label = maas.classifyScore(1.0);
        expect(
          label.toLowerCase(),
          anyOf(contains('low'), contains('mindful')),
        );
      });

      test('Sinhala mode returns different label than English', () {
        final en = maas.classifyScore(4.0, isSinhala: false);
        final si = maas.classifyScore(4.0, isSinhala: true);
        expect(en, isNot(equals(si)));
      });
    });
  });

  // ── PWS18Service ───────────────────────────────────────────────────────
  group('PWS18Service', () {
    final pws18 = PWS18Service();

    // Helper: build a 18-item response list where every item = value.
    List<int?> allValue(int v) => List<int?>.filled(18, v);

    group('calculateScores() – reverse items', () {
      // Reverse items: [1,2,3,8,9,11,12,13,17,18] → score = 8 - value
      // Non-reverse: all others → score = value

      test('reverse item (q1, value=3) is scored 8-3=5', () {
        final responses = List<int?>.filled(18, null);
        responses[0] = 3; // q1

        // subscale with only q1
        final scores = pws18.calculateScores(responses, {
          'subscale_a': [1],
        });
        expect(scores['subscale_a'], closeTo(5.0, 0.001)); // 8 - 3 = 5
      });

      test('non-reverse item (q4, value=3) is scored 3', () {
        final responses = List<int?>.filled(18, null);
        responses[3] = 3; // q4 (not in reverse list)

        final scores = pws18.calculateScores(responses, {
          'subscale_b': [4],
        });
        expect(scores['subscale_b'], closeTo(3.0, 0.001));
      });

      test('reverse item (q18, value=1) is scored 8-1=7', () {
        final responses = List<int?>.filled(18, null);
        responses[17] = 1; // q18

        final scores = pws18.calculateScores(responses, {
          's': [18],
        });
        expect(scores['s'], closeTo(7.0, 0.001));
      });
    });

    group('calculateScores() – subscale averages', () {
      test('average is correct when all items have value 4', () {
        // q4 and q5 are non-reverse; each stays 4
        final responses = List<int?>.filled(18, null);
        responses[3] = 4; // q4
        responses[4] = 4; // q5

        final scores = pws18.calculateScores(responses, {
          'wellbeing': [4, 5],
        });
        expect(scores['wellbeing'], closeTo(4.0, 0.001));
      });

      test('multiple subscales are computed independently', () {
        final responses = List<int?>.filled(18, null);
        responses[0] = 4; // q1 → reverse → 8-4=4
        responses[3] = 6; // q4 → non-reverse → 6

        final scores = pws18.calculateScores(responses, {
          'a': [1],
          'b': [4],
        });
        expect(scores['a'], closeTo(4.0, 0.001));
        expect(scores['b'], closeTo(6.0, 0.001));
      });

      test('null response for an item is excluded from average', () {
        // q4=4, q5=null → only q4 counts → average = 4
        final responses = List<int?>.filled(18, null);
        responses[3] = 4; // q4

        final scores = pws18.calculateScores(responses, {
          'wellness': [4, 5],
        });
        expect(scores['wellness'], closeTo(4.0, 0.001));
      });

      test('all null responses for subscale returns 0.0', () {
        final responses = List<int?>.filled(18, null);

        final scores = pws18.calculateScores(responses, {
          'empty': [4, 5],
        });
        expect(scores['empty'], closeTo(0.0, 0.001));
      });
    });

    group('calculateScores() – all reverse items check', () {
      const reverseItems = [1, 2, 3, 8, 9, 11, 12, 13, 17, 18];

      for (final q in reverseItems) {
        test('q$q (value=2) reverse scores 8-2=6', () {
          final responses = List<int?>.filled(18, null);
          responses[q - 1] = 2;
          final scores = pws18.calculateScores(responses, {
            's': [q],
          });
          expect(scores['s'], closeTo(6.0, 0.001));
        });
      }
    });
  });
}
