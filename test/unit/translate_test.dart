import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/services/localization_service.dart';
import 'package:mamamind/utils/translate.dart';

Future<void> _loadTranslations() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  LocalizationService.instance.reset();
  await LocalizationService.instance.loadTranslations();
}

void main() {
  setUpAll(_loadTranslations);

  // ── Translate.withLang() factory ──────────────────────────────────────────
  group('Translate.withLang()', () {
    test('creates an English instance with correct lang getter', () {
      final t = Translate.withLang('en');
      expect(t.lang, 'en');
    });

    test('creates a Sinhala instance with correct lang getter', () {
      final t = Translate.withLang('si');
      expect(t.lang, 'si');
    });

    test('isEnglish is true for lang="en"', () {
      expect(Translate.withLang('en').isEnglish, isTrue);
    });

    test('isEnglish is false for lang="si"', () {
      expect(Translate.withLang('si').isEnglish, isFalse);
    });

    test('isSinhala is true for lang="si"', () {
      expect(Translate.withLang('si').isSinhala, isTrue);
    });

    test('isSinhala is false for lang="en"', () {
      expect(Translate.withLang('en').isSinhala, isFalse);
    });
  });

  // ── Delegate methods — English ─────────────────────────────────────────────
  group('Translate delegate methods in English', () {
    late Translate t;
    setUpAll(() => t = Translate.withLang('en'));

    test('common() returns non-empty string for appName', () {
      expect(t.common('appName'), isNotEmpty);
    });

    test('auth() returns non-empty string for login', () {
      expect(t.auth('login'), isNotEmpty);
    });

    test('home() returns non-empty string for welcome', () {
      expect(t.home('welcome'), isNotEmpty);
    });

    test('home() returns non-empty string for startSession', () {
      expect(t.home('startSession'), isNotEmpty);
    });

    test('profile() returns non-empty string for profile', () {
      expect(t.profile('profile'), isNotEmpty);
    });

    test('profile() returns non-empty string for settings', () {
      expect(t.profile('settings'), isNotEmpty);
    });

    test('chat() returns non-empty string for mindfulChat', () {
      expect(t.chat('mindfulChat'), isNotEmpty);
    });

    test('chat() returns non-empty string for send', () {
      expect(t.chat('send'), isNotEmpty);
    });

    test('questionnaires() returns non-empty string for normal', () {
      expect(t.questionnaires('normal'), isNotEmpty);
    });

    test('questionnaires() returns non-empty string for mild', () {
      expect(t.questionnaires('mild'), isNotEmpty);
    });

    test('achievements() returns non-empty string for achievements', () {
      expect(t.achievements('achievements'), isNotEmpty);
    });

    test('achievements() returns non-empty string for unlocked', () {
      expect(t.achievements('unlocked'), isNotEmpty);
    });

    test('validators() returns non-empty string for emailRequired', () {
      expect(t.validators('emailRequired'), isNotEmpty);
    });

    test('validators() returns non-empty string for passwordRequired', () {
      expect(t.validators('passwordRequired'), isNotEmpty);
    });

    test('notifications() returns non-empty string for notifications', () {
      expect(t.notifications('notifications'), isNotEmpty);
    });

    test(
      'notifications() returns non-empty string for meditationReminders',
      () {
        expect(t.notifications('meditationReminders'), isNotEmpty);
      },
    );

    test('privacyPolicy() returns non-empty string for title', () {
      expect(t.privacyPolicy('title'), isNotEmpty);
    });

    test('unknown key returns the key as fallback', () {
      expect(t.common('__no_such_key__'), equals('__no_such_key__'));
    });
  });

  // ── Delegate methods — Sinhala ─────────────────────────────────────────────
  group('Translate delegate methods in Sinhala', () {
    late Translate t;
    setUpAll(() => t = Translate.withLang('si'));

    test('common() returns non-empty Sinhala string for appName', () {
      expect(t.common('appName'), isNotEmpty);
    });

    test('auth() returns non-empty Sinhala string for login', () {
      expect(t.auth('login'), isNotEmpty);
    });

    test('home() returns non-empty Sinhala string for welcome', () {
      expect(t.home('welcome'), isNotEmpty);
    });

    test('questionnaires() returns non-empty Sinhala string for normal', () {
      expect(t.questionnaires('normal'), isNotEmpty);
    });

    test(
      'achievements() returns non-empty Sinhala string for achievements',
      () {
        expect(t.achievements('achievements'), isNotEmpty);
      },
    );
  });

  // ── EN vs SI produce different strings ────────────────────────────────────
  group('English and Sinhala translations differ', () {
    test('auth login key differs between EN and SI', () {
      final en = Translate.withLang('en').auth('login');
      final si = Translate.withLang('si').auth('login');
      expect(en, isNot(equals(si)));
    });

    test('home welcome key differs between EN and SI', () {
      final en = Translate.withLang('en').home('welcome');
      final si = Translate.withLang('si').home('welcome');
      expect(en, isNot(equals(si)));
    });

    test('questionnaires normal key differs between EN and SI', () {
      final en = Translate.withLang('en').questionnaires('normal');
      final si = Translate.withLang('si').questionnaires('normal');
      expect(en, isNot(equals(si)));
    });

    test('achievements achievements key differs between EN and SI', () {
      final en = Translate.withLang('en').achievements('achievements');
      final si = Translate.withLang('si').achievements('achievements');
      expect(en, isNot(equals(si)));
    });

    test('notifications key differs between EN and SI', () {
      final en = Translate.withLang('en').notifications('notifications');
      final si = Translate.withLang('si').notifications('notifications');
      expect(en, isNot(equals(si)));
    });
  });
}
