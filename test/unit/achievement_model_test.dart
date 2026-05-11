import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/models/achievement_model.dart';
import 'package:mamamind/models/achievement_data.dart';

void main() {
  // ── AchievementModel ──────────────────────────────────────────────────
  group('AchievementModel', () {
    group('fromMap()', () {
      test('parses all fields from a full map', () {
        final map = {
          'title': 'First Step',
          'description': 'Watched the first video.',
          'icon': '🏆',
        };
        final model = AchievementModel.fromMap(map, 'doc-01');

        expect(model.id, 'doc-01');
        expect(model.title, 'First Step');
        expect(model.description, 'Watched the first video.');
        expect(model.icon, '🏆');
      });

      test('applies default icon ⭐ when icon is absent', () {
        final map = <String, dynamic>{'title': 'Test', 'description': 'Desc'};
        final model = AchievementModel.fromMap(map, 'doc-02');

        expect(model.icon, '⭐');
      });

      test('applies empty strings for missing title and description', () {
        final model = AchievementModel.fromMap({}, 'doc-03');

        expect(model.title, '');
        expect(model.description, '');
      });
    });

    group('toMap()', () {
      test('serialises all fields', () {
        final model = AchievementModel(
          id: 'doc-04',
          title: 'Zen Mom',
          description: 'Completed all videos.',
          icon: '🌸',
        );
        final map = model.toMap();

        expect(map['title'], 'Zen Mom');
        expect(map['description'], 'Completed all videos.');
        expect(map['icon'], '🌸');
        // id is not stored inside the document
        expect(map.containsKey('id'), isFalse);
      });

      test('round-trips through fromMap -> toMap', () {
        final original = {
          'title': 'Self Aware',
          'description': 'Did DASS-21.',
          'icon': '🧠',
        };
        final model = AchievementModel.fromMap(original, 'doc-05');
        final roundTripped = model.toMap();

        expect(roundTripped['title'], original['title']);
        expect(roundTripped['description'], original['description']);
        expect(roundTripped['icon'], original['icon']);
      });
    });
  });

  // ── AchievementData ───────────────────────────────────────────────────
  group('AchievementData', () {
    test('allAchievements list is not empty', () {
      expect(AchievementData.allAchievements, isNotEmpty);
    });

    test('all achievement IDs are unique', () {
      final ids = AchievementData.allAchievements.map((a) => a.id).toList();
      expect(ids.length, equals(ids.toSet().length));
    });

    test('every achievement has non-empty id, titles and descriptions', () {
      for (final a in AchievementData.allAchievements) {
        expect(a.id, isNotEmpty, reason: 'id empty for ${a.id}');
        expect(a.titleEn, isNotEmpty, reason: 'titleEn empty for ${a.id}');
        expect(a.titleSi, isNotEmpty, reason: 'titleSi empty for ${a.id}');
        expect(
          a.descriptionEn,
          isNotEmpty,
          reason: 'descriptionEn empty for ${a.id}',
        );
        expect(
          a.descriptionSi,
          isNotEmpty,
          reason: 'descriptionSi empty for ${a.id}',
        );
      }
    });

    group('findById()', () {
      test('returns the correct achievement for a known id', () {
        final result = AchievementData.findById('first_step');

        expect(result, isNotNull);
        expect(result!.id, 'first_step');
        expect(result.titleEn, 'First Step');
      });

      test('returns null for an unknown id', () {
        expect(AchievementData.findById('does_not_exist'), isNull);
      });

      test('finds every id in allAchievements', () {
        for (final a in AchievementData.allAchievements) {
          final found = AchievementData.findById(a.id);
          expect(found, isNotNull, reason: 'Could not find ${a.id}');
          expect(found!.id, a.id);
        }
      });

      test('returns null for empty string', () {
        expect(AchievementData.findById(''), isNull);
      });
    });

    test('super_mom achievement exists in the list', () {
      final superMom = AchievementData.findById('super_mom');
      expect(superMom, isNotNull);
    });

    test('all questionnaire-related achievements exist', () {
      for (final id in ['self_aware', 'mindful_observer', 'happiness_seeker']) {
        expect(
          AchievementData.findById(id),
          isNotNull,
          reason: '$id not found',
        );
      }
    });

    test('all video-milestone achievements exist', () {
      for (final id in ['first_step', 'halfway_there', 'zen_master']) {
        expect(
          AchievementData.findById(id),
          isNotNull,
          reason: '$id not found',
        );
      }
    });

    test('journal and mood achievements exist', () {
      for (final id in [
        'first_journal',
        'journal_writer',
        'mood_check_in',
        'mood_tracker',
      ]) {
        expect(
          AchievementData.findById(id),
          isNotNull,
          reason: '$id not found',
        );
      }
    });

    test('chat_companion achievement exists', () {
      expect(AchievementData.findById('chat_companion'), isNotNull);
    });
  });
}
