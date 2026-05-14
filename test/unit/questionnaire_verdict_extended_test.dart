import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/services/questionnaire_verdict_service.dart';

// ── Helper ────────────────────────────────────────────────────────────────────
Map<String, dynamic> _attempt(int dep, int anx, int stress) => {
  'scores': {'depression': dep, 'anxiety': anx, 'stress': stress},
};

void main() {
  // ── DASS21VerdictEngine — trendCode branches not covered in base tests ─────
  group('DASS21VerdictEngine.compute() — additional trendCode scenarios', () {
    // ── stable: Stable & Healthy ────────────────────────────────────────────
    //   All 3 attempts at normal levels → comp3 = 0 (≤ 3) → stable_healthy
    test(
      'trendCode "stable" and label "Stable & Healthy" when all scores normal across attempts',
      () {
        final attempts = {
          1: _attempt(0, 0, 0),
          2: _attempt(0, 0, 0),
          3: _attempt(0, 0, 0),
        };
        final verdict = DASS21VerdictEngine.compute(attempts);

        expect(verdict.trendCode, 'stable');
        expect(verdict.trendLabel, contains('Healthy'));
        expect(verdict.emoji, '💚');
      },
    );

    // ── stable: Stable — Needs Support ──────────────────────────────────────
    //   All 3 attempts same elevated scores → delta=0, comp3=4 (> 3)
    //   dep=14 (sev=2), anx=10 (sev=2), str=0 (sev=0) → comp=4
    test(
      'trendCode "stable" and label contains "Needs Support" when elevated but unchanged',
      () {
        final attempts = {
          1: _attempt(14, 10, 0),
          2: _attempt(14, 10, 0),
          3: _attempt(14, 10, 0),
        };
        final verdict = DASS21VerdictEngine.compute(attempts);

        expect(verdict.trendCode, 'stable');
        expect(verdict.trendLabel, contains('Support'));
        expect(verdict.emoji, '💙');
      },
    );

    // ── fluctuating: Mixed Progress ─────────────────────────────────────────
    //   a1: dep=14(sev=2), anx=10(sev=2), str=0(sev=0) → comp1=4
    //   a2: dep=10(sev=1), anx=15(sev=3), str=0(sev=0)
    //   a3: dep=14(sev=2), anx=10(sev=2), str=15(sev=1) → comp3=5
    //   overallDelta = 1 (≤ 2)
    //   depLvl=[2,1,2] → d12=-1,d23=1 → "improved then plateaued" (contains 'improved')
    //   anxLvl=[2,3,2] → d12=1,d23=-1 → "peaked mid-way then improved" (contains 'improved')
    //   strLvl=[0,0,1] → d12=0,d23=1 → sum=1>0 → "consistently worsened"
    //   improvingCount=2 ≥ 2 → "Mixed Progress"
    test(
      'trendCode "fluctuating" and label "Mixed Progress" when two subscales improved',
      () {
        final attempts = {
          1: _attempt(14, 10, 0),
          2: _attempt(10, 15, 0),
          3: _attempt(14, 10, 15),
        };
        final verdict = DASS21VerdictEngine.compute(attempts);

        expect(verdict.trendCode, 'fluctuating');
        expect(verdict.trendLabel, contains('Mixed'));
        expect(verdict.emoji, '🔄');
      },
    );

    // ── fluctuating: Slight Fluctuation ─────────────────────────────────────
    //   a1: dep=0(sev=0), anx=0(sev=0), str=0(sev=0) → comp1=0
    //   a2: dep=10(sev=1), anx=8(sev=1), str=0(sev=0)
    //   a3: dep=10(sev=1), anx=8(sev=1), str=0(sev=0) → comp3=2
    //   overallDelta = 2 (≤ 2)
    //   depLvl=[0,1,1] → d12=1,d23=0 → sum=1>0 → "consistently worsened"
    //   anxLvl=[0,1,1] → same → "consistently worsened"
    //   strLvl=[0,0,0] → d12=0,d23=0 → sum=0 → "remained stable"
    //   improvingCount=1 < 2 → "Slight Fluctuation"
    test(
      'trendCode "fluctuating" and label "Slight Fluctuation" when only one subscale stable',
      () {
        final attempts = {
          1: _attempt(0, 0, 0),
          2: _attempt(10, 8, 0),
          3: _attempt(10, 8, 0),
        };
        final verdict = DASS21VerdictEngine.compute(attempts);

        expect(verdict.trendCode, 'fluctuating');
        expect(verdict.trendLabel, contains('Fluctuation'));
        expect(verdict.emoji, '⚡');
      },
    );

    // ── declining: Needs Attention ───────────────────────────────────────────
    //   a1: all normal (comp1=0)
    //   a3: dep=10(sev=1), anx=8(sev=1), str=15(sev=1) → comp3=3
    //   overallDelta = 3 (> 2) → declining
    test(
      'trendCode "declining" and label "Needs Attention" when scores worsen significantly',
      () {
        final attempts = {
          1: _attempt(0, 0, 0),
          2: _attempt(0, 0, 0),
          3: _attempt(10, 8, 15),
        };
        final verdict = DASS21VerdictEngine.compute(attempts);

        expect(verdict.trendCode, 'declining');
        expect(verdict.trendLabel, contains('Attention'));
        expect(verdict.emoji, '⚠️');
      },
    );
  });

  // ── Sinhala content ───────────────────────────────────────────────────────
  group('DASS21VerdictEngine.compute() — Sinhala content', () {
    test('trendLabelSi is non-empty for all trendCode branches', () {
      final scenarios = [
        // improving (strong)
        {
          1: _attempt(42, 42, 42),
          2: _attempt(20, 14, 25),
          3: _attempt(0, 0, 0),
        },
        // stable healthy
        {1: _attempt(0, 0, 0), 2: _attempt(0, 0, 0), 3: _attempt(0, 0, 0)},
        // stable needs support
        {
          1: _attempt(14, 10, 0),
          2: _attempt(14, 10, 0),
          3: _attempt(14, 10, 0),
        },
        // declining
        {1: _attempt(0, 0, 0), 2: _attempt(0, 0, 0), 3: _attempt(10, 8, 15)},
      ];

      for (final attempts in scenarios) {
        final verdict = DASS21VerdictEngine.compute(attempts);
        expect(
          verdict.trendLabelSi,
          isNotEmpty,
          reason: 'trendLabelSi empty for trendCode=${verdict.trendCode}',
        );
        expect(
          verdict.summarySi,
          isNotEmpty,
          reason: 'summarySi empty for trendCode=${verdict.trendCode}',
        );
      }
    });

    test('subscaleInsightsSi contains Sinhala subscale keys', () {
      final attempts = {
        1: _attempt(0, 0, 0),
        2: _attempt(0, 0, 0),
        3: _attempt(0, 0, 0),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);

      expect(verdict.subscaleInsightsSi.containsKey('මානසික අවපීඩනය'), isTrue);
      expect(verdict.subscaleInsightsSi.containsKey('කාංසාව'), isTrue);
      expect(verdict.subscaleInsightsSi.containsKey('ආතතිය'), isTrue);
    });

    test('subscaleInsightsSi values are non-empty', () {
      final attempts = {
        1: _attempt(10, 8, 15),
        2: _attempt(14, 10, 19),
        3: _attempt(0, 0, 0),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);

      for (final entry in verdict.subscaleInsightsSi.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: 'Sinhala insight is empty for subscale: ${entry.key}',
        );
      }
    });
  });

  // ── Subscale trend phrases ────────────────────────────────────────────────
  group('DASS21VerdictEngine.compute() — subscale trend phrases', () {
    test('consistently improving trend reflected in subscaleInsights', () {
      // dep: [4→2→0] → consistently improved
      // anx: [4→2→0] → consistently improved
      // str: [4→2→0] → consistently improved
      final attempts = {
        1: _attempt(28, 20, 34),
        2: _attempt(14, 10, 26),
        3: _attempt(0, 0, 0),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);

      final depInsight = verdict.subscaleInsights['Depression'] ?? '';
      expect(depInsight.toLowerCase(), contains('improved'));
    });

    test('consistently worsening trend reflected in subscaleInsights', () {
      // dep: [0→2→4] → consistently worsened
      final attempts = {
        1: _attempt(0, 0, 0),
        2: _attempt(14, 0, 0),
        3: _attempt(28, 0, 0),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);

      final depInsight = verdict.subscaleInsights['Depression'] ?? '';
      expect(depInsight.toLowerCase(), contains('worsen'));
    });

    test('stable trend reflected in subscaleInsights', () {
      // str stays at sev=0 across all 3 → "remained stable"
      final attempts = {
        1: _attempt(0, 0, 0),
        2: _attempt(0, 0, 0),
        3: _attempt(0, 0, 0),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);

      final strInsight = verdict.subscaleInsights['Stress'] ?? '';
      expect(strInsight.toLowerCase(), contains('stable'));
    });

    test('subscaleInsights contains final severity level label', () {
      final attempts = {
        1: _attempt(0, 0, 0),
        2: _attempt(0, 0, 0),
        3: _attempt(0, 0, 0),
      };
      final verdict = DASS21VerdictEngine.compute(attempts);

      final depInsight = verdict.subscaleInsights['Depression'] ?? '';
      // Final depression severity = Normal (score 0)
      expect(depInsight, contains('Normal'));
    });
  });

  // ── computedAt ───────────────────────────────────────────────────────────
  group('DASS21VerdictEngine.compute() — computedAt', () {
    test('computedAt is a recent DateTime', () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final verdict = DASS21VerdictEngine.compute({
        1: _attempt(0, 0, 0),
        2: _attempt(0, 0, 0),
        3: _attempt(0, 0, 0),
      });
      final after = DateTime.now().add(const Duration(seconds: 2));

      expect(verdict.computedAt.isAfter(before), isTrue);
      expect(verdict.computedAt.isBefore(after), isTrue);
    });
  });
}
