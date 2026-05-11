import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/models/mood_entry.dart';

void main() {
  group('MoodEntry', () {
    // ── Static data ──────────────────────────────────────────────────────
    group('static lists', () {
      test('emojis list has exactly 5 entries', () {
        expect(MoodEntry.emojis.length, 5);
      });

      test('labelsEn list has exactly 5 entries', () {
        expect(MoodEntry.labelsEn.length, 5);
      });

      test('labelsSi list has exactly 5 entries', () {
        expect(MoodEntry.labelsSi.length, 5);
      });

      test('emojis are in sad-to-happy order', () {
        // Index 0 = saddest, 4 = happiest.
        expect(MoodEntry.emojis.first, '😢');
        expect(MoodEntry.emojis.last, '😄');
      });

      test('labelsEn are correct from index 0 to 4', () {
        expect(MoodEntry.labelsEn[0], 'Very Sad');
        expect(MoodEntry.labelsEn[1], 'Sad');
        expect(MoodEntry.labelsEn[2], 'Neutral');
        expect(MoodEntry.labelsEn[3], 'Happy');
        expect(MoodEntry.labelsEn[4], 'Very Happy');
      });
    });

    // ── emoji getter ─────────────────────────────────────────────────────
    group('emoji getter', () {
      test('returns the correct emoji for each valid index', () {
        for (int i = 0; i <= 4; i++) {
          final entry = MoodEntry(
            id: 'e$i',
            moodIndex: i,
            createdAt: DateTime.now(),
          );
          expect(entry.emoji, MoodEntry.emojis[i]);
        }
      });

      test('clamps below-range index to 0', () {
        final entry = MoodEntry(
          id: 'low',
          moodIndex: -5,
          createdAt: DateTime.now(),
        );
        expect(entry.emoji, MoodEntry.emojis[0]);
      });

      test('clamps above-range index to 4', () {
        final entry = MoodEntry(
          id: 'high',
          moodIndex: 99,
          createdAt: DateTime.now(),
        );
        expect(entry.emoji, MoodEntry.emojis[4]);
      });
    });

    // ── labelEn / labelSi ────────────────────────────────────────────────
    group('labelEn()', () {
      test('returns correct English label for each index', () {
        final expected = ['Very Sad', 'Sad', 'Neutral', 'Happy', 'Very Happy'];
        for (int i = 0; i <= 4; i++) {
          final entry = MoodEntry(
            id: 'e$i',
            moodIndex: i,
            createdAt: DateTime.now(),
          );
          expect(entry.labelEn(), expected[i]);
        }
      });
    });

    group('labelSi()', () {
      test('returns correct Sinhala label for index 2 (Neutral)', () {
        final entry = MoodEntry(
          id: 'si',
          moodIndex: 2,
          createdAt: DateTime.now(),
        );
        expect(entry.labelSi(), 'සාමාන්‍යයෙන්');
      });
    });

    // ── toMap() ──────────────────────────────────────────────────────────
    group('toMap()', () {
      test('serialises moodIndex, note and createdAt', () {
        final now = DateTime(2026, 1, 15, 10, 0);
        final entry = MoodEntry(
          id: 'map-test',
          moodIndex: 3,
          note: 'Feeling good',
          createdAt: now,
        );
        final map = entry.toMap();

        expect(map['moodIndex'], 3);
        expect(map['note'], 'Feeling good');
        expect(map.containsKey('createdAt'), isTrue);
      });

      test('includes null note when note is null', () {
        final entry = MoodEntry(
          id: 'no-note',
          moodIndex: 2,
          createdAt: DateTime.now(),
        );
        final map = entry.toMap();

        expect(map.containsKey('note'), isTrue);
        expect(map['note'], isNull);
      });
    });

    // ── Optional note field ───────────────────────────────────────────────
    group('note field', () {
      test('note is null by default', () {
        final entry = MoodEntry(
          id: 'no-note',
          moodIndex: 1,
          createdAt: DateTime.now(),
        );
        expect(entry.note, isNull);
      });

      test('note is stored correctly when provided', () {
        final entry = MoodEntry(
          id: 'with-note',
          moodIndex: 4,
          note: 'Excellent day!',
          createdAt: DateTime.now(),
        );
        expect(entry.note, 'Excellent day!');
      });
    });
  });
}
