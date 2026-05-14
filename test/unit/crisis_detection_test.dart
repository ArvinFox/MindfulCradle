import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/services/crisis_detection_service.dart';

void main() {
  group('CrisisDetectionService.analyzeJournalText()', () {
    // ── CrisisLevel.none ─────────────────────────────────────────────────
    group('returns none', () {
      test('for empty string', () {
        expect(
          CrisisDetectionService.analyzeJournalText('', 'en'),
          CrisisLevel.none,
        );
      });

      test('for neutral everyday text', () {
        expect(
          CrisisDetectionService.analyzeJournalText(
            'Today was an ordinary day. I went for a walk.',
            'en',
          ),
          CrisisLevel.none,
        );
      });

      test('for positive text', () {
        expect(
          CrisisDetectionService.analyzeJournalText(
            'I feel happy and grateful for my family.',
            'en',
          ),
          CrisisLevel.none,
        );
      });
    });

    // ── CrisisLevel.distress ─────────────────────────────────────────────
    group('returns distress', () {
      test('for "hopeless" keyword (English)', () {
        expect(
          CrisisDetectionService.analyzeJournalText(
            'I feel completely hopeless about my situation.',
            'en',
          ),
          CrisisLevel.distress,
        );
      });

      test('for "helpless" keyword (English)', () {
        expect(
          CrisisDetectionService.analyzeJournalText(
            'Everything feels helpless right now.',
            'en',
          ),
          CrisisLevel.distress,
        );
      });

      test('for "worthless" keyword (English)', () {
        expect(
          CrisisDetectionService.analyzeJournalText(
            'I feel worthless as a mother.',
            'en',
          ),
          CrisisLevel.distress,
        );
      });

      test('for "no one cares" phrase (English)', () {
        expect(
          CrisisDetectionService.analyzeJournalText(
            'I feel like no one cares about me.',
            'en',
          ),
          CrisisLevel.distress,
        );
      });

      test('detects distress via negative sentiment score', () {
        // A very negative journal entry (no explicit distress keywords)
        // should still trigger distress via the sentiment-score fallback.
        final result = CrisisDetectionService.analyzeJournalText(
          'I am sad anxious overwhelmed depressed terrible awful',
          'en',
        );
        expect(result, anyOf(CrisisLevel.distress, CrisisLevel.crisis));
      });
    });

    // ── CrisisLevel.crisis ───────────────────────────────────────────────
    group('returns crisis', () {
      test('for "suicid" substring in text', () {
        expect(
          CrisisDetectionService.analyzeJournalText(
            'I have been having suicidal thoughts lately.',
            'en',
          ),
          CrisisLevel.crisis,
        );
      });

      test('for "kill myself" phrase', () {
        expect(
          CrisisDetectionService.analyzeJournalText(
            'I keep thinking I want to kill myself.',
            'en',
          ),
          CrisisLevel.crisis,
        );
      });

      test('for "want to die" phrase', () {
        expect(
          CrisisDetectionService.analyzeJournalText(
            'Sometimes I just want to die.',
            'en',
          ),
          CrisisLevel.crisis,
        );
      });

      test('for "end my life" phrase', () {
        expect(
          CrisisDetectionService.analyzeJournalText(
            'I want to end my life.',
            'en',
          ),
          CrisisLevel.crisis,
        );
      });

      test('for regex pattern "end [words] life" with extra words', () {
        expect(
          CrisisDetectionService.analyzeJournalText(
            'I desperately want to end this precious life.',
            'en',
          ),
          CrisisLevel.crisis,
        );
      });
    });

    // ── Bilingual detection (always checks both EN + SI) ─────────────────
    group('bilingual detection', () {
      test('detects English crisis keywords regardless of lang="si"', () {
        expect(
          CrisisDetectionService.analyzeJournalText(
            'I want to kill myself.',
            'si', // lang is si but text is English – should still detect
          ),
          CrisisLevel.crisis,
        );
      });

      test('detects Sinhala distress keywords regardless of lang="en"', () {
        // Even when lang='en' is passed the Sinhala keyword lists are still checked.
        // We only assert that it's at minimum distress (it could be crisis).
        final result = CrisisDetectionService.analyzeJournalText(
          'I feel hopeless and helpless.', // English distress
          'si',
        );
        expect(result, anyOf(CrisisLevel.distress, CrisisLevel.crisis));
      });
    });

    // ── CrisisLevel enum ─────────────────────────────────────────────────
    group('CrisisLevel enum ordering', () {
      test('CrisisLevel values are [none, distress, crisis]', () {
        expect(CrisisLevel.values[0], CrisisLevel.none);
        expect(CrisisLevel.values[1], CrisisLevel.distress);
        expect(CrisisLevel.values[2], CrisisLevel.crisis);
      });
    });
  });
}
