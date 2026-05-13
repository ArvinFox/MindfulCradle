import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/services/localization_service.dart';

Future<void> _loadTranslations() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  LocalizationService.instance.reset();
  await LocalizationService.instance.loadTranslations();
}

void main() {
  setUpAll(_loadTranslations);

  // ── home() ─────────────────────────────────────────────────────────────────
  group('LocalizationService home()', () {
    test('returns non-empty English string for welcome', () {
      expect(LocalizationService.instance.home('welcome', 'en'), isNotEmpty);
    });

    test('returns non-empty Sinhala string for welcome', () {
      expect(LocalizationService.instance.home('welcome', 'si'), isNotEmpty);
    });

    test('EN and SI welcome differ', () {
      final en = LocalizationService.instance.home('welcome', 'en');
      final si = LocalizationService.instance.home('welcome', 'si');
      expect(en, isNot(equals(si)));
    });

    test('returns non-empty string for startSession in EN', () {
      expect(
        LocalizationService.instance.home('startSession', 'en'),
        isNotEmpty,
      );
    });

    test('returns non-empty string for completed in EN', () {
      expect(LocalizationService.instance.home('completed', 'en'), isNotEmpty);
    });

    test('returns non-empty string for locked in EN', () {
      expect(LocalizationService.instance.home('locked', 'en'), isNotEmpty);
    });

    test('returns non-empty string for continueWatching in SI', () {
      expect(
        LocalizationService.instance.home('continueWatching', 'si'),
        isNotEmpty,
      );
    });

    test('returns non-empty string for mindfulnessSessions in EN', () {
      expect(
        LocalizationService.instance.home('mindfulnessSessions', 'en'),
        isNotEmpty,
      );
    });
  });

  // ── profile() ─────────────────────────────────────────────────────────────
  group('LocalizationService profile()', () {
    test('returns non-empty English string for profile key', () {
      expect(LocalizationService.instance.profile('profile', 'en'), isNotEmpty);
    });

    test('returns non-empty Sinhala string for profile key', () {
      expect(LocalizationService.instance.profile('profile', 'si'), isNotEmpty);
    });

    test('EN and SI profile key differ', () {
      final en = LocalizationService.instance.profile('profile', 'en');
      final si = LocalizationService.instance.profile('profile', 'si');
      expect(en, isNot(equals(si)));
    });

    test('returns non-empty string for settings in EN', () {
      expect(
        LocalizationService.instance.profile('settings', 'en'),
        isNotEmpty,
      );
    });

    test('returns non-empty string for deleteAccount in EN', () {
      expect(
        LocalizationService.instance.profile('deleteAccount', 'en'),
        isNotEmpty,
      );
    });

    test('returns non-empty string for exportData in SI', () {
      expect(
        LocalizationService.instance.profile('exportData', 'si'),
        isNotEmpty,
      );
    });
  });

  // ── chat() ────────────────────────────────────────────────────────────────
  group('LocalizationService chat()', () {
    test('returns non-empty English string for mindfulChat', () {
      expect(
        LocalizationService.instance.chat('mindfulChat', 'en'),
        isNotEmpty,
      );
    });

    test('returns non-empty Sinhala string for mindfulChat', () {
      expect(
        LocalizationService.instance.chat('mindfulChat', 'si'),
        isNotEmpty,
      );
    });

    test('EN and SI mindfulChat differ', () {
      final en = LocalizationService.instance.chat('mindfulChat', 'en');
      final si = LocalizationService.instance.chat('mindfulChat', 'si');
      expect(en, isNot(equals(si)));
    });

    test('returns non-empty string for send in EN', () {
      expect(LocalizationService.instance.chat('send', 'en'), isNotEmpty);
    });

    test('returns non-empty string for newChat in EN', () {
      expect(LocalizationService.instance.chat('newChat', 'en'), isNotEmpty);
    });

    test('returns non-empty string for thinking in SI', () {
      expect(LocalizationService.instance.chat('thinking', 'si'), isNotEmpty);
    });

    test('returns non-empty string for welcomeMessage in EN', () {
      expect(
        LocalizationService.instance.chat('welcomeMessage', 'en'),
        isNotEmpty,
      );
    });
  });

  // ── achievements() ────────────────────────────────────────────────────────
  group('LocalizationService achievements()', () {
    test('returns non-empty English string for achievements key', () {
      expect(
        LocalizationService.instance.achievements('achievements', 'en'),
        isNotEmpty,
      );
    });

    test('returns non-empty Sinhala string for achievements key', () {
      expect(
        LocalizationService.instance.achievements('achievements', 'si'),
        isNotEmpty,
      );
    });

    test('EN and SI achievements key differ', () {
      final en = LocalizationService.instance.achievements(
        'achievements',
        'en',
      );
      final si = LocalizationService.instance.achievements(
        'achievements',
        'si',
      );
      expect(en, isNot(equals(si)));
    });

    test('returns non-empty string for unlocked in EN', () {
      expect(
        LocalizationService.instance.achievements('unlocked', 'en'),
        isNotEmpty,
      );
    });

    test('returns non-empty string for congratulations in EN', () {
      expect(
        LocalizationService.instance.achievements('congratulations', 'en'),
        isNotEmpty,
      );
    });

    test('returns non-empty string for achievementUnlocked in SI', () {
      expect(
        LocalizationService.instance.achievements('achievementUnlocked', 'si'),
        isNotEmpty,
      );
    });

    test('returns non-empty string for noAchievements in EN', () {
      expect(
        LocalizationService.instance.achievements('noAchievements', 'en'),
        isNotEmpty,
      );
    });
  });

  // ── notifications() ──────────────────────────────────────────────────────
  group('LocalizationService notifications()', () {
    test('returns non-empty English string for notifications key', () {
      expect(
        LocalizationService.instance.notifications('notifications', 'en'),
        isNotEmpty,
      );
    });

    test('returns non-empty Sinhala string for notifications key', () {
      expect(
        LocalizationService.instance.notifications('notifications', 'si'),
        isNotEmpty,
      );
    });

    test('EN and SI notifications key differ', () {
      final en = LocalizationService.instance.notifications(
        'notifications',
        'en',
      );
      final si = LocalizationService.instance.notifications(
        'notifications',
        'si',
      );
      expect(en, isNot(equals(si)));
    });

    test('returns non-empty string for meditationReminders in EN', () {
      expect(
        LocalizationService.instance.notifications('meditationReminders', 'en'),
        isNotEmpty,
      );
    });

    test('returns non-empty string for reminderTime in EN', () {
      expect(
        LocalizationService.instance.notifications('reminderTime', 'en'),
        isNotEmpty,
      );
    });

    test('returns non-empty string for wellnessReminders in SI', () {
      expect(
        LocalizationService.instance.notifications('wellnessReminders', 'si'),
        isNotEmpty,
      );
    });
  });

  // ── privacyPolicy() ──────────────────────────────────────────────────────
  group('LocalizationService privacyPolicy()', () {
    test('returns non-empty English string for title key', () {
      expect(
        LocalizationService.instance.privacyPolicy('title', 'en'),
        isNotEmpty,
      );
    });

    test('returns non-empty Sinhala string for title key', () {
      expect(
        LocalizationService.instance.privacyPolicy('title', 'si'),
        isNotEmpty,
      );
    });

    test('EN and SI title differ', () {
      final en = LocalizationService.instance.privacyPolicy('title', 'en');
      final si = LocalizationService.instance.privacyPolicy('title', 'si');
      expect(en, isNot(equals(si)));
    });

    test('returns non-empty string for appBarTitle in EN', () {
      expect(
        LocalizationService.instance.privacyPolicy('appBarTitle', 'en'),
        isNotEmpty,
      );
    });

    test('returns non-empty string for s1Title in EN', () {
      expect(
        LocalizationService.instance.privacyPolicy('s1Title', 'en'),
        isNotEmpty,
      );
    });
  });

  // ── fallback behaviour across all categories ──────────────────────────────
  group('Fallback behaviour for unknown keys across all categories', () {
    const missing = '__missing__';

    test('home() returns the key as fallback', () {
      expect(LocalizationService.instance.home(missing, 'en'), equals(missing));
    });

    test('profile() returns the key as fallback', () {
      expect(
        LocalizationService.instance.profile(missing, 'en'),
        equals(missing),
      );
    });

    test('chat() returns the key as fallback', () {
      expect(LocalizationService.instance.chat(missing, 'en'), equals(missing));
    });

    test('achievements() returns the key as fallback', () {
      expect(
        LocalizationService.instance.achievements(missing, 'en'),
        equals(missing),
      );
    });

    test('notifications() returns the key as fallback', () {
      expect(
        LocalizationService.instance.notifications(missing, 'en'),
        equals(missing),
      );
    });

    test('privacyPolicy() returns the key as fallback', () {
      expect(
        LocalizationService.instance.privacyPolicy(missing, 'en'),
        equals(missing),
      );
    });
  });
}
