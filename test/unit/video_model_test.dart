import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/models/video_model.dart';
import 'package:mamamind/models/user_progress.dart';

void main() {
  // ── VideoModel ────────────────────────────────────────────────────────
  group('VideoModel', () {
    group('fromMap()', () {
      test('parses a complete map correctly', () {
        final map = {
          'title': 'Breathing Exercises',
          'titleSi': 'හුස්ම ව්‍යායාම',
          'youtubeId': 'abc123',
          'youtubeIdSi': 'xyz789',
          'duration': 480,
          'sessionNumber': 2,
        };
        final video = VideoModel.fromMap(map, 'vid-01');

        expect(video.id, 'vid-01');
        expect(video.title, 'Breathing Exercises');
        expect(video.titleSi, 'හුස්ම ව්‍යායාම');
        expect(video.youtubeId, 'abc123');
        expect(video.youtubeIdSi, 'xyz789');
        expect(video.duration, 480);
        expect(video.sessionNumber, 2);
      });

      test('applies default values when fields are absent', () {
        final video = VideoModel.fromMap({}, 'vid-02');

        expect(video.title, '');
        expect(video.titleSi, '');
        expect(video.youtubeId, '');
        expect(video.youtubeIdSi, '');
        expect(video.duration, 0);
        expect(video.sessionNumber, 1);
      });
    });

    group('toMap()', () {
      test('serialises all fields', () {
        final video = VideoModel(
          id: 'vid-03',
          title: 'Mindfulness',
          titleSi: 'සිහිකල්පනාව',
          youtubeId: 'yt111',
          youtubeIdSi: 'yt222',
          duration: 600,
          sessionNumber: 3,
        );
        final map = video.toMap();

        expect(map['title'], 'Mindfulness');
        expect(map['titleSi'], 'සිහිකල්පනාව');
        expect(map['youtubeId'], 'yt111');
        expect(map['youtubeIdSi'], 'yt222');
        expect(map['duration'], 600);
        expect(map['sessionNumber'], 3);
        expect(map.containsKey('id'), isFalse);
      });

      test('round-trips correctly through fromMap -> toMap', () {
        final original = {
          'title': 'Relaxation',
          'titleSi': 'ලිහිල් කිරීම',
          'youtubeId': 'r1',
          'youtubeIdSi': 'r2',
          'duration': 300,
          'sessionNumber': 1,
        };
        final video = VideoModel.fromMap(original, 'vid-04');
        final map = video.toMap();

        expect(map['title'], original['title']);
        expect(map['youtubeId'], original['youtubeId']);
        expect(map['duration'], original['duration']);
      });
    });

    // ── getYoutubeId() ────────────────────────────────────────────────────
    group('getYoutubeId()', () {
      late VideoModel video;

      setUp(() {
        video = VideoModel(
          id: 'vid',
          title: 'Test',
          titleSi: 'Test SI',
          youtubeId: 'en-id',
          youtubeIdSi: 'si-id',
          duration: 100,
          sessionNumber: 1,
        );
      });

      test('returns English id when lang is "en"', () {
        expect(video.getYoutubeId('en'), 'en-id');
      });

      test('returns Sinhala id when lang is "si" and youtubeIdSi is set', () {
        expect(video.getYoutubeId('si'), 'si-id');
      });

      test('falls back to English id when youtubeIdSi is empty', () {
        final noSi = VideoModel(
          id: 'vid2',
          title: 'Test',
          titleSi: '',
          youtubeId: 'en-only',
          youtubeIdSi: '',
          duration: 100,
          sessionNumber: 1,
        );
        expect(noSi.getYoutubeId('si'), 'en-only');
      });
    });
  });

  // ── UserProgressModel ─────────────────────────────────────────────────
  group('UserProgressModel', () {
    group('initial()', () {
      test('creates a progress entry with 0.0 progress and not completed', () {
        final progress = UserProgressModel.initial(
          userId: 'user-01',
          videoId: 'vid-01',
        );

        expect(progress.userId, 'user-01');
        expect(progress.videoId, 'vid-01');
        expect(progress.progress, 0.0);
        expect(progress.completed, isFalse);
      });
    });

    group('fromMap()', () {
      test('parses a complete map correctly', () {
        final map = {
          'userId': 'user-01',
          'videoId': 'vid-01',
          'progress': 0.75,
          'completed': true,
        };
        final progress = UserProgressModel.fromMap(map);

        expect(progress.userId, 'user-01');
        expect(progress.videoId, 'vid-01');
        expect(progress.progress, closeTo(0.75, 0.001));
        expect(progress.completed, isTrue);
      });

      test('applies safe defaults when fields are absent', () {
        final progress = UserProgressModel.fromMap({});

        expect(progress.userId, '');
        expect(progress.videoId, '');
        expect(progress.progress, 0.0);
        expect(progress.completed, isFalse);
      });

      test('casts int progress value to double', () {
        final map = {
          'userId': 'u',
          'videoId': 'v',
          'progress': 1, // stored as int
          'completed': false,
        };
        final progress = UserProgressModel.fromMap(map);
        expect(progress.progress, isA<double>());
        expect(progress.progress, 1.0);
      });
    });

    group('toMap()', () {
      test('serialises all fields', () {
        final progress = UserProgressModel(
          userId: 'user-02',
          videoId: 'vid-02',
          progress: 0.5,
          completed: false,
        );
        final map = progress.toMap();

        expect(map['userId'], 'user-02');
        expect(map['videoId'], 'vid-02');
        expect(map['progress'], closeTo(0.5, 0.001));
        expect(map['completed'], isFalse);
      });
    });
  });
}
