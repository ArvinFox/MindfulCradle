import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/models/user_model.dart';

void main() {
  group('UserModel', () {
    // ── newUser factory ────────────────────────────────────────────────────
    group('newUser()', () {
      test('creates a user with the correct id, name and email', () {
        final user = UserModel.newUser(
          id: 'uid-001',
          fullName: 'Kasuni Perera',
          email: 'kasuni@example.com',
        );

        expect(user.id, 'uid-001');
        expect(user.fullName, 'Kasuni Perera');
        expect(user.email, 'kasuni@example.com');
      });

      test('sets sane defaults for a brand-new user', () {
        final user = UserModel.newUser(
          id: 'uid-001',
          fullName: 'Kasuni Perera',
          email: 'kasuni@example.com',
        );

        expect(user.photoUrl, isNull);
        expect(user.achievements, isEmpty);
        expect(user.unlockedVideos, equals([1]));
        expect(user.totalSessionTime, 0);
        expect(user.videoWatchTime, 0);
        expect(user.isUserRegistrationComplete, isFalse);
        expect(user.isTutorialDone, isFalse);
      });
    });

    // ── fromMap factory ────────────────────────────────────────────────────
    group('fromMap()', () {
      test('parses a complete Firestore document correctly', () {
        final map = {
          'fullName': 'Kasuni Perera',
          'email': 'kasuni@example.com',
          'photoUrl': 'https://example.com/photo.jpg',
          'achievements': ['first_login', 'mood_streak_7'],
          'unlockedVideos': [1, 2, 3],
          'totalSessionTime': 300,
          'videoWatchTime': 120,
          'isUserRegistrationComplete': true,
          'isTutorialDone': true,
        };

        final user = UserModel.fromMap(map, 'uid-001');

        expect(user.id, 'uid-001');
        expect(user.fullName, 'Kasuni Perera');
        expect(user.email, 'kasuni@example.com');
        expect(user.photoUrl, 'https://example.com/photo.jpg');
        expect(user.achievements, ['first_login', 'mood_streak_7']);
        expect(user.unlockedVideos, [1, 2, 3]);
        expect(user.totalSessionTime, 300);
        expect(user.videoWatchTime, 120);
        expect(user.isUserRegistrationComplete, isTrue);
        expect(user.isTutorialDone, isTrue);
      });

      test('applies safe defaults when optional fields are absent', () {
        final map = {'fullName': 'Malini', 'email': 'malini@example.com'};

        final user = UserModel.fromMap(map, 'uid-002');

        expect(user.photoUrl, isNull);
        expect(user.achievements, isEmpty);
        expect(user.unlockedVideos, isEmpty);
        expect(user.totalSessionTime, 0);
        expect(user.videoWatchTime, 0);
        expect(user.isUserRegistrationComplete, isFalse);
        // Existing users without the field should default to true.
        expect(user.isTutorialDone, isTrue);
      });

      test('sums videoWatchTime correctly when stored as a map', () {
        final map = {
          'fullName': 'Malini',
          'email': 'malini@example.com',
          'achievements': <String>[],
          'unlockedVideos': <int>[],
          'totalSessionTime': 0,
          'isUserRegistrationComplete': false,
          // Map form: individual video durations
          'videoWatchTime': {'video_1': 45, 'video_2': 30, 'video_3': 15},
        };

        final user = UserModel.fromMap(map, 'uid-003');

        expect(user.videoWatchTime, 90); // 45 + 30 + 15
      });

      test('handles empty string fields gracefully', () {
        final map = <String, dynamic>{'fullName': null, 'email': null};

        final user = UserModel.fromMap(map, 'uid-004');

        expect(user.fullName, '');
        expect(user.email, '');
      });
    });

    // ── toMap ──────────────────────────────────────────────────────────────
    group('toMap()', () {
      test('serialises all fields correctly', () {
        final user = UserModel(
          id: 'uid-001',
          fullName: 'Kasuni Perera',
          email: 'kasuni@example.com',
          photoUrl: 'https://example.com/photo.jpg',
          achievements: ['first_login'],
          unlockedVideos: [1, 2],
          totalSessionTime: 200,
          videoWatchTime: 80,
          isUserRegistrationComplete: true,
          isTutorialDone: true,
        );

        final map = user.toMap();

        expect(map['fullName'], 'Kasuni Perera');
        expect(map['email'], 'kasuni@example.com');
        expect(map['photoUrl'], 'https://example.com/photo.jpg');
        expect(map['achievements'], ['first_login']);
        expect(map['unlockedVideos'], [1, 2]);
        expect(map['totalSessionTime'], 200);
        expect(map['videoWatchTime'], 80);
        expect(map['isUserRegistrationComplete'], isTrue);
        expect(map['isTutorialDone'], isTrue);
      });

      test('omits photoUrl key when photoUrl is null', () {
        final user = UserModel(
          id: 'uid-001',
          fullName: 'Kasuni',
          email: 'kasuni@example.com',
          photoUrl: null,
          achievements: [],
          unlockedVideos: [],
          totalSessionTime: 0,
          videoWatchTime: 0,
          isUserRegistrationComplete: false,
        );

        final map = user.toMap();

        expect(map.containsKey('photoUrl'), isFalse);
      });

      test('round-trips correctly through fromMap -> toMap', () {
        final original = {
          'fullName': 'Kasuni Perera',
          'email': 'kasuni@example.com',
          'photoUrl': 'https://example.com/photo.jpg',
          'achievements': ['first_login'],
          'unlockedVideos': [1, 2],
          'totalSessionTime': 100,
          'videoWatchTime': 40,
          'isUserRegistrationComplete': true,
          'isTutorialDone': true,
        };

        final user = UserModel.fromMap(original, 'uid-001');
        final roundTripped = user.toMap();

        expect(roundTripped['fullName'], original['fullName']);
        expect(roundTripped['email'], original['email']);
        expect(roundTripped['achievements'], original['achievements']);
        expect(roundTripped['totalSessionTime'], original['totalSessionTime']);
        expect(
          roundTripped['isUserRegistrationComplete'],
          original['isUserRegistrationComplete'],
        );
      });
    });

    // ── copyWith ───────────────────────────────────────────────────────────
    group('copyWith()', () {
      late UserModel base;

      setUp(() {
        base = UserModel.newUser(
          id: 'uid-001',
          fullName: 'Kasuni',
          email: 'kasuni@example.com',
        );
      });

      test('produces a new instance with updated fields', () {
        final updated = base.copyWith(
          fullName: 'Kasuni Perera',
          isUserRegistrationComplete: true,
          isTutorialDone: true,
        );

        expect(updated.fullName, 'Kasuni Perera');
        expect(updated.isUserRegistrationComplete, isTrue);
        expect(updated.isTutorialDone, isTrue);
      });

      test('preserves unchanged fields from the original', () {
        final updated = base.copyWith(fullName: 'Kasuni Perera');

        expect(updated.id, base.id);
        expect(updated.email, base.email);
        expect(updated.achievements, base.achievements);
        expect(updated.unlockedVideos, base.unlockedVideos);
        expect(updated.totalSessionTime, base.totalSessionTime);
      });

      test('calling with no arguments produces an equal copy', () {
        final copy = base.copyWith();

        expect(copy.id, base.id);
        expect(copy.fullName, base.fullName);
        expect(copy.email, base.email);
        expect(copy.photoUrl, base.photoUrl);
      });

      test('can update achievements list independently', () {
        final updated = base.copyWith(
          achievements: ['first_login', 'mood_streak_3'],
        );

        expect(updated.achievements, ['first_login', 'mood_streak_3']);
        // Base should be unchanged.
        expect(base.achievements, isEmpty);
      });
    });
  });
}
