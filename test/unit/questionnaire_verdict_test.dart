import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/services/questionnaire_verdict_service.dart';

// Helper to build an attempt map entry.
Map<String, dynamic> _attempt(int dep, int anx, int stress) => {
  'scores': {'depression': dep, 'anxiety': anx, 'stress': stress},
};

void main() {
  // ── QuestionnaireVerdict.fromMap() ────────────────────────────────────
  group('QuestionnaireVerdict.fromMap()', () {
    test('parses a complete map correctly', () {
      final map = <String, dynamic>{
        'trendLabel': 'Strong Improvement',
        'trendLabelSi': 'විශිෂ්ට ප්‍රගතියක්',
        'emoji': '🌟',
        'summary': 'Great progress!',
        'summarySi': 'ඉතා හොඳ ප්‍රගතියක්!',
        'subscaleInsights': {'depression': 'improving', 'anxiety': 'stable'},
        'subscaleInsightsSi': {'depression': 'වැඩිදියුණු', 'anxiety': 'ස්ථාවර'},
        'trendCode': 'improving',
        'computedAt': null, // Timestamp not used in pure unit tests
      };
      final verdict = QuestionnaireVerdict.fromMap(map);

      expect(verdict.trendLabel, 'Strong Improvement');
      expect(verdict.trendLabelSi, 'විශිෂ්ට ප්‍රගතියක්');
      expect(verdict.emoji, '🌟');
      expect(verdict.summary, 'Great progress!');
      expect(verdict.trendCode, 'improving');
      expect(verdict.subscaleInsights['depression'], 'improving');
    });

    test('applies safe defaults for missing fields', () {
      final verdict = QuestionnaireVerdict.fromMap({});

      expect(verdict.trendLabel, '');
      expect(verdict.emoji, '');
      expect(verdict.trendCode, 'stable'); // default trendCode
      expect(verdict.subscaleInsights, isEmpty);
      expect(verdict.subscaleInsightsSi, isEmpty);
    });

    test('defaults trendCode to "stable" when missing', () {
      final verdict = QuestionnaireVerdict.fromMap({'trendLabel': 'X'});
      expect(verdict.trendCode, 'stable');
    });
  });

  // ── DASS21VerdictEngine.compute() ────────────────────────────────────
  group('DASS21VerdictEngine.compute()', () {
    test('returns trendCode "improving" when comp3 - comp1 <= -4', () {
      // Attempt 1: all extreme → severity 4+4+4=12
      // Attempt 3: all normal  → severity 0+0+0=0
      // delta = 0 - 12 = -12 (strong improvement)
      final attempts = {
        1: _attempt(42, 42, 42),
        2: _attempt(20, 14, 25),
        3: _attempt(0, 0, 0),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);

      expect(verdict.trendCode, 'improving');
      expect(verdict.trendLabel, contains('Improvement'));
    });

    test('returns trendCode "improving" when comp3 - comp1 is -1 (gradual)', () {
      // Attempt 1: dep=10(mild=1), anx=8(mild=1), stress=15(mild=1) → comp1=3
      // Attempt 3: dep=9(normal=0), anx=7(normal=0), stress=14(normal=0) → comp3=0
      // delta = 0-3 = -3 < 0 → 'improving'
      final attempts = {
        1: _attempt(10, 8, 15),
        2: _attempt(10, 8, 15),
        3: _attempt(9, 7, 14),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);

      expect(verdict.trendCode, 'improving');
    });

    test('returns trendCode "declining" when comp3 - comp1 >= 4', () {
      // Attempt 1: all normal → comp1=0
      // Attempt 3: all severe+ → comp3≥12
      final attempts = {
        1: _attempt(0, 0, 0),
        2: _attempt(14, 9, 18),
        3: _attempt(42, 42, 42),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);

      expect(verdict.trendCode, 'declining');
    });

    test('returns trendCode "stable" when no meaningful change', () {
      // All 3 attempts the same → delta = 0 → stable
      final attempts = {
        1: _attempt(9, 7, 14),
        2: _attempt(9, 7, 14),
        3: _attempt(9, 7, 14),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);

      expect(verdict.trendCode, 'stable');
    });

    test('verdict contains non-empty emoji', () {
      final attempts = {
        1: _attempt(0, 0, 0),
        2: _attempt(0, 0, 0),
        3: _attempt(0, 0, 0),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);
      expect(verdict.emoji, isNotEmpty);
    });

    test('verdict contains English and Sinhala summaries', () {
      final attempts = {
        1: _attempt(0, 0, 0),
        2: _attempt(0, 0, 0),
        3: _attempt(0, 0, 0),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);
      expect(verdict.summary, isNotEmpty);
      expect(verdict.summarySi, isNotEmpty);
    });

    test('subscaleInsights contains all three subscales', () {
      final attempts = {
        1: _attempt(10, 10, 20),
        2: _attempt(10, 10, 20),
        3: _attempt(10, 10, 20),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);
      // Keys are capitalised in the implementation ('Depression', etc.)
      expect(verdict.subscaleInsights.containsKey('Depression'), isTrue);
      expect(verdict.subscaleInsights.containsKey('Anxiety'), isTrue);
      expect(verdict.subscaleInsights.containsKey('Stress'), isTrue);
    });

    test('fluctuating: worsens mid-way then improves', () {
      // Attempt 1: normal (low)
      // Attempt 2: severe (high) → worsens
      // Attempt 3: normal (low)  → improves
      final attempts = {
        1: _attempt(0, 0, 0),
        2: _attempt(42, 42, 42),
        3: _attempt(0, 0, 0),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);
      // delta = comp3(0) - comp1(0) = 0 → stable or fluctuating
      expect(verdict.trendCode, anyOf('stable', 'fluctuating'));
    });
  });
}
