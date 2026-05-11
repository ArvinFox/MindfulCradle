// JournalEntry doesn't depend on Firebase for construction –
// only fromFirestore() needs a DocumentSnapshot.  We test the pure
// data-holding and toMap() behaviour here.
import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/models/journal_entry.dart';

void main() {
  final fixedDate = DateTime(2025, 6, 15, 9, 30);

  group('JournalEntry', () {
    final sampleEntry = JournalEntry(
      id: 'j-001',
      title: 'A Good Day',
      content: 'I felt happy today.',
      sentiment: 'positive',
      sentimentScore: 0.8,
      semanticTags: ['emotions', 'family'],
      createdAt: fixedDate,
      language: 'en',
    );

    group('construction', () {
      test('stores all fields correctly', () {
        expect(sampleEntry.id, 'j-001');
        expect(sampleEntry.title, 'A Good Day');
        expect(sampleEntry.content, 'I felt happy today.');
        expect(sampleEntry.sentiment, 'positive');
        expect(sampleEntry.sentimentScore, closeTo(0.8, 0.001));
        expect(sampleEntry.semanticTags, ['emotions', 'family']);
        expect(sampleEntry.createdAt, fixedDate);
        expect(sampleEntry.language, 'en');
      });

      test('accepts Sinhala language code', () {
        final si = JournalEntry(
          id: 'j-si',
          title: 'සතුට',
          content: 'අද මා සතුටු ය.',
          sentiment: 'positive',
          sentimentScore: 0.6,
          semanticTags: [],
          createdAt: fixedDate,
          language: 'si',
        );
        expect(si.language, 'si');
      });
    });

    group('toMap()', () {
      test('includes all expected keys', () {
        final map = sampleEntry.toMap();

        expect(map.containsKey('title'), isTrue);
        expect(map.containsKey('content'), isTrue);
        expect(map.containsKey('sentiment'), isTrue);
        expect(map.containsKey('sentimentScore'), isTrue);
        expect(map.containsKey('semanticTags'), isTrue);
        expect(map.containsKey('createdAt'), isTrue);
        expect(map.containsKey('language'), isTrue);
        // id is the document id – not stored inside the map
        expect(map.containsKey('id'), isFalse);
      });

      test('serialises title and content correctly', () {
        final map = sampleEntry.toMap();
        expect(map['title'], 'A Good Day');
        expect(map['content'], 'I felt happy today.');
      });

      test('serialises sentiment and score correctly', () {
        final map = sampleEntry.toMap();
        expect(map['sentiment'], 'positive');
        expect((map['sentimentScore'] as num).toDouble(), closeTo(0.8, 0.001));
      });

      test('serialises semanticTags as a List', () {
        final map = sampleEntry.toMap();
        expect(map['semanticTags'], isA<List>());
        expect(map['semanticTags'], containsAll(['emotions', 'family']));
      });

      test('serialises language correctly', () {
        final map = sampleEntry.toMap();
        expect(map['language'], 'en');
      });

      test('negative sentimentScore is preserved', () {
        final negative = JournalEntry(
          id: 'j-neg',
          title: 'Bad Day',
          content: 'Felt hopeless.',
          sentiment: 'negative',
          sentimentScore: -0.7,
          semanticTags: [],
          createdAt: fixedDate,
          language: 'en',
        );
        final map = negative.toMap();
        expect((map['sentimentScore'] as num).toDouble(), closeTo(-0.7, 0.001));
        expect(map['sentiment'], 'negative');
      });

      test('neutral sentiment with score 0.0 is preserved', () {
        final neutral = JournalEntry(
          id: 'j-neutral',
          title: 'Average',
          content: 'Just another day.',
          sentiment: 'neutral',
          sentimentScore: 0.0,
          semanticTags: [],
          createdAt: fixedDate,
          language: 'en',
        );
        final map = neutral.toMap();
        expect(map['sentiment'], 'neutral');
        expect((map['sentimentScore'] as num).toDouble(), 0.0);
      });

      test('empty semanticTags list is preserved', () {
        final noTags = JournalEntry(
          id: 'j-notags',
          title: 'No Tags',
          content: 'Nothing special.',
          sentiment: 'neutral',
          sentimentScore: 0.0,
          semanticTags: [],
          createdAt: fixedDate,
          language: 'en',
        );
        final map = noTags.toMap();
        expect(map['semanticTags'], isEmpty);
      });
    });
  });
}
