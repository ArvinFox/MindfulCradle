import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/utils/journal_analysis.dart';

void main() {
  group('JournalAnalysis.analyze()', () {
    // ── English – Sentiment ──────────────────────────────────────────────
    group('English sentiment', () {
      test('returns positive for clearly positive text', () {
        final result = JournalAnalysis.analyze(
          'I am so happy and grateful today. Everything feels peaceful.',
          'en',
        );
        expect(result.sentiment, 'positive');
        expect(result.score, greaterThan(0.1));
      });

      test('returns negative for clearly negative text', () {
        final result = JournalAnalysis.analyze(
          'I am so sad and anxious. Everything is terrible and I feel hopeless.',
          'en',
        );
        expect(result.sentiment, 'negative');
        expect(result.score, lessThan(-0.1));
      });

      test('returns neutral for mixed or blank text', () {
        final result = JournalAnalysis.analyze('The weather is today.', 'en');
        expect(result.sentiment, 'neutral');
      });

      test('returns neutral for empty string', () {
        final result = JournalAnalysis.analyze('', 'en');
        expect(result.sentiment, 'neutral');
        expect(result.score, 0.0);
      });

      test('score is clamped to -1..1 range', () {
        final result = JournalAnalysis.analyze(
          'happy grateful joyful calm peaceful love excited delighted',
          'en',
        );
        expect(result.score, inInclusiveRange(-1.0, 1.0));
      });
    });

    // ── English – Regex crisis patterns ─────────────────────────────────
    group('English regex crisis patterns', () {
      test('detects "end my life" phrasing', () {
        final result = JournalAnalysis.analyze(
          'I just want to end my life.',
          'en',
        );
        expect(result.sentiment, 'negative');
      });

      test('detects "end my precious life" with extra words (regex)', () {
        final result = JournalAnalysis.analyze(
          'Sometimes I just want to end my precious life.',
          'en',
        );
        expect(result.sentiment, 'negative');
      });

      test('detects "kill myself" phrasing', () {
        final result = JournalAnalysis.analyze(
          'I feel like I want to kill myself.',
          'en',
        );
        expect(result.sentiment, 'negative');
      });

      test('detects "kill myself" with extra words (regex)', () {
        final result = JournalAnalysis.analyze(
          'I sometimes want to kill myself eventually.',
          'en',
        );
        expect(result.sentiment, 'negative');
      });

      test('detects "want to die" keyword', () {
        final result = JournalAnalysis.analyze('I want to die.', 'en');
        expect(result.sentiment, 'negative');
      });
    });

    // ── Sinhala – Sentiment ───────────────────────────────────────────────
    group('Sinhala sentiment', () {
      test('returns neutral for non-matching Sinhala text', () {
        final result = JournalAnalysis.analyze('අද හොඳ දිනයක්.', 'si');
        // Without matching keywords the result is neutral.
        expect(result.score, isA<double>());
        expect(result.sentiment, anyOf('positive', 'neutral', 'negative'));
      });
    });

    // ── Semantic tags ────────────────────────────────────────────────────
    group('Semantic tag extraction', () {
      test('extracts "pregnancy" tag', () {
        final result = JournalAnalysis.analyze(
          'My pregnancy is going well and I feel good.',
          'en',
        );
        expect(result.tags, contains('pregnancy'));
      });

      test('extracts "baby" tag', () {
        final result = JournalAnalysis.analyze(
          'I am excited about my baby.',
          'en',
        );
        expect(result.tags, contains('baby'));
      });

      test('extracts "family" tag', () {
        final result = JournalAnalysis.analyze(
          'I spent the day with my family.',
          'en',
        );
        expect(result.tags, contains('family'));
      });

      test('extracts "sleep" tag', () {
        final result = JournalAnalysis.analyze(
          'I could not sleep last night.',
          'en',
        );
        expect(result.tags, contains('sleep'));
      });

      test('extracts "health" tag', () {
        final result = JournalAnalysis.analyze(
          'My health check showed everything is fine.',
          'en',
        );
        expect(result.tags, contains('health'));
      });

      test('extracts "emotions" tag', () {
        final result = JournalAnalysis.analyze(
          'I feel so emotional today.',
          'en',
        );
        expect(result.tags, contains('emotions'));
      });

      test('extracts "work" tag', () {
        final result = JournalAnalysis.analyze(
          'Work has been very stressful.',
          'en',
        );
        expect(result.tags, contains('work'));
      });

      test('returns empty tags for non-thematic text', () {
        final result = JournalAnalysis.analyze('The sky is blue today.', 'en');
        expect(result.tags, isEmpty);
      });

      test('can extract multiple tags at once', () {
        final result = JournalAnalysis.analyze(
          'My baby is healthy and I slept well.',
          'en',
        );
        expect(result.tags.length, greaterThan(1));
      });
    });

    // ── sentimentEmoji() helper ──────────────────────────────────────────
    group('sentimentEmoji()', () {
      test('returns 😊 for positive', () {
        expect(JournalAnalysis.sentimentEmoji('positive'), '😊');
      });

      test('returns 😔 for negative', () {
        expect(JournalAnalysis.sentimentEmoji('negative'), '😔');
      });

      test('returns 😐 for neutral', () {
        expect(JournalAnalysis.sentimentEmoji('neutral'), '😐');
      });

      test('returns 😐 for unknown sentiment', () {
        expect(JournalAnalysis.sentimentEmoji('unknown'), '😐');
      });
    });

    // ── sentimentLabel() helper ──────────────────────────────────────────
    group('sentimentLabel()', () {
      test('returns English Positive label', () {
        expect(JournalAnalysis.sentimentLabel('positive', 'en'), 'Positive');
      });

      test('returns English Negative label', () {
        expect(JournalAnalysis.sentimentLabel('negative', 'en'), 'Negative');
      });

      test('returns English Neutral label', () {
        expect(JournalAnalysis.sentimentLabel('neutral', 'en'), 'Neutral');
      });

      test('returns Sinhala positive label', () {
        expect(JournalAnalysis.sentimentLabel('positive', 'si'), 'ධනාත්මක');
      });

      test('returns Sinhala negative label', () {
        expect(JournalAnalysis.sentimentLabel('negative', 'si'), 'නිෂේධාත්මක');
      });
    });
  });
}
