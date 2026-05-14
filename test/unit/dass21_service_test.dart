import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/services/dass21_service.dart';
import 'package:mamamind/services/localization_service.dart';

void main() {
  late DASS21Service service;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    LocalizationService.instance.reset();
    await LocalizationService.instance.loadTranslations();
    service = DASS21Service();
  });

  // ── calculateScores() ───────────────────────────────────────────────────
  group('DASS21Service.calculateScores()', () {
    test('returns zero scores when all responses are null', () {
      final responses = List<int?>.filled(21, null);
      final scores = service.calculateScores(responses);

      expect(scores['depression'], 0);
      expect(scores['anxiety'], 0);
      expect(scores['stress'], 0);
    });

    test('multiplies raw sum by 2 (DASS-21 scoring rule)', () {
      // Answering all 21 questions with value 1.
      // Depression questions (7): raw sum = 7 → score = 14
      // Anxiety    questions (7): raw sum = 7 → score = 14
      // Stress     questions (7): raw sum = 7 → score = 14
      final responses = List<int?>.filled(21, 1);
      final scores = service.calculateScores(responses);

      expect(scores['depression'], 14);
      expect(scores['anxiety'], 14);
      expect(scores['stress'], 14);
    });

    test('only depression questions contribute to depression score', () {
      // Set all to 0, then set each depression question (3,5,10,13,16,17,21) to 1.
      final responses = List<int?>.filled(21, 0);
      for (final q in [3, 5, 10, 13, 16, 17, 21]) {
        responses[q - 1] = 1;
      }
      final scores = service.calculateScores(responses);

      expect(scores['depression'], 14); // 7 × 1 × 2 = 14
      expect(scores['anxiety'], 0);
      expect(scores['stress'], 0);
    });

    test('only anxiety questions contribute to anxiety score', () {
      final responses = List<int?>.filled(21, 0);
      for (final q in [2, 4, 7, 9, 15, 19, 20]) {
        responses[q - 1] = 1;
      }
      final scores = service.calculateScores(responses);

      expect(scores['depression'], 0);
      expect(scores['anxiety'], 14);
      expect(scores['stress'], 0);
    });

    test('only stress questions contribute to stress score', () {
      final responses = List<int?>.filled(21, 0);
      for (final q in [1, 6, 8, 11, 12, 14, 18]) {
        responses[q - 1] = 1;
      }
      final scores = service.calculateScores(responses);

      expect(scores['depression'], 0);
      expect(scores['anxiety'], 0);
      expect(scores['stress'], 14);
    });

    test(
      'maximum score is 42 per subscale (all answers = 3, raw = 21, ×2 = 42)',
      () {
        final responses = List<int?>.filled(21, 3);
        final scores = service.calculateScores(responses);

        expect(scores['depression'], 42);
        expect(scores['anxiety'], 42);
        expect(scores['stress'], 42);
      },
    );

    test('nulls are treated as 0 for that question', () {
      // All depression questions answered with 2, anxiety/stress null.
      final responses = List<int?>.filled(21, null);
      for (final q in [3, 5, 10, 13, 16, 17, 21]) {
        responses[q - 1] = 2;
      }
      final scores = service.calculateScores(responses);

      expect(scores['depression'], 28); // 7 × 2 × 2 = 28
      expect(scores['anxiety'], 0);
      expect(scores['stress'], 0);
    });
  });

  // ── classifyDepression() ────────────────────────────────────────────────
  group('DASS21Service.classifyDepression()', () {
    test('score 0 → normal', () {
      final label = service.classifyDepression(0);
      expect(label.toLowerCase(), contains('normal'));
    });

    test('score 9 → normal (boundary)', () {
      final label = service.classifyDepression(9);
      expect(label.toLowerCase(), contains('normal'));
    });

    test('score 10 → mild (boundary)', () {
      final label = service.classifyDepression(10);
      expect(label.toLowerCase(), contains('mild'));
    });

    test('score 13 → mild (boundary)', () {
      final label = service.classifyDepression(13);
      expect(label.toLowerCase(), contains('mild'));
    });

    test('score 14 → moderate (boundary)', () {
      final label = service.classifyDepression(14);
      expect(label.toLowerCase(), contains('moderate'));
    });

    test('score 20 → moderate (boundary)', () {
      final label = service.classifyDepression(20);
      expect(label.toLowerCase(), contains('moderate'));
    });

    test('score 21 → severe (boundary)', () {
      final label = service.classifyDepression(21);
      expect(label.toLowerCase(), contains('severe'));
    });

    test('score 27 → severe (boundary)', () {
      final label = service.classifyDepression(27);
      expect(label.toLowerCase(), contains('severe'));
    });

    test('score 28 → extremely severe (boundary)', () {
      final label = service.classifyDepression(28);
      expect(
        label.toLowerCase(),
        anyOf(contains('extreme'), contains('severe')),
      );
    });

    test('score 42 → extremely severe (maximum)', () {
      final label = service.classifyDepression(42);
      expect(
        label.toLowerCase(),
        anyOf(contains('extreme'), contains('severe')),
      );
    });

    test('Sinhala mode returns non-English label', () {
      final en = service.classifyDepression(0, isSinhala: false);
      final si = service.classifyDepression(0, isSinhala: true);
      expect(en, isNot(equals(si)));
    });
  });

  // ── classifyAnxiety() ───────────────────────────────────────────────────
  group('DASS21Service.classifyAnxiety()', () {
    test('score 0 → normal', () {
      expect(service.classifyAnxiety(0).toLowerCase(), contains('normal'));
    });

    test('score 7 → normal (boundary)', () {
      expect(service.classifyAnxiety(7).toLowerCase(), contains('normal'));
    });

    test('score 8 → mild (boundary)', () {
      expect(service.classifyAnxiety(8).toLowerCase(), contains('mild'));
    });

    test('score 9 → mild (boundary)', () {
      expect(service.classifyAnxiety(9).toLowerCase(), contains('mild'));
    });

    test('score 10 → moderate (boundary)', () {
      expect(service.classifyAnxiety(10).toLowerCase(), contains('moderate'));
    });

    test('score 14 → moderate (boundary)', () {
      expect(service.classifyAnxiety(14).toLowerCase(), contains('moderate'));
    });

    test('score 15 → severe (boundary)', () {
      expect(service.classifyAnxiety(15).toLowerCase(), contains('severe'));
    });

    test('score 19 → severe (boundary)', () {
      expect(service.classifyAnxiety(19).toLowerCase(), contains('severe'));
    });

    test('score 20 → extremely severe (boundary)', () {
      expect(
        service.classifyAnxiety(20).toLowerCase(),
        anyOf(contains('extreme'), contains('severe')),
      );
    });
  });

  // ── classifyStress() ────────────────────────────────────────────────────
  group('DASS21Service.classifyStress()', () {
    test('score 0 → normal', () {
      expect(service.classifyStress(0).toLowerCase(), contains('normal'));
    });

    test('score 14 → normal (boundary)', () {
      expect(service.classifyStress(14).toLowerCase(), contains('normal'));
    });

    test('score 15 → mild (boundary)', () {
      expect(service.classifyStress(15).toLowerCase(), contains('mild'));
    });

    test('score 18 → mild (boundary)', () {
      expect(service.classifyStress(18).toLowerCase(), contains('mild'));
    });

    test('score 19 → moderate (boundary)', () {
      expect(service.classifyStress(19).toLowerCase(), contains('moderate'));
    });

    test('score 25 → moderate (boundary)', () {
      expect(service.classifyStress(25).toLowerCase(), contains('moderate'));
    });

    test('score 26 → severe (boundary)', () {
      expect(service.classifyStress(26).toLowerCase(), contains('severe'));
    });

    test('score 33 → severe (boundary)', () {
      expect(service.classifyStress(33).toLowerCase(), contains('severe'));
    });

    test('score 34 → extremely severe (boundary)', () {
      expect(
        service.classifyStress(34).toLowerCase(),
        anyOf(contains('extreme'), contains('severe')),
      );
    });
  });
}
