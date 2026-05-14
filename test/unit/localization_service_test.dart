import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/services/localization_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    LocalizationService.instance.reset();
    await LocalizationService.instance.loadTranslations();
  });

  group('LocalizationService', () {
    test('singleton always returns the same instance', () {
      final a = LocalizationService.instance;
      final b = LocalizationService.instance;
      expect(identical(a, b), isTrue);
    });

    test('common() returns a non-empty string for appName in English', () {
      final val = LocalizationService.instance.common('appName', 'en');
      expect(val, isNotEmpty);
    });

    test('auth() returns a non-empty string for login key in English', () {
      final val = LocalizationService.instance.auth('login', 'en');
      expect(val, isNotEmpty);
    });

    test('auth() returns a non-empty string for login key in Sinhala', () {
      final val = LocalizationService.instance.auth('login', 'si');
      expect(val, isNotEmpty);
    });

    test('common() with unknown key returns the key itself as fallback', () {
      final val = LocalizationService.instance.common('__missing_key__', 'en');
      expect(val, isNotNull);
      expect(val, equals('__missing_key__'));
    });

    test(
      'questionnaires() returns a non-empty label for "normal" in English',
      () {
        final val = LocalizationService.instance.questionnaires('normal', 'en');
        expect(val, isNotEmpty);
      },
    );

    test(
      'questionnaires() returns a non-empty label for "normal" in Sinhala',
      () {
        final val = LocalizationService.instance.questionnaires('normal', 'si');
        expect(val, isNotEmpty);
      },
    );

    test(
      'questionnaires() returns different values for "mild" in EN vs SI',
      () {
        final en = LocalizationService.instance.questionnaires('mild', 'en');
        final si = LocalizationService.instance.questionnaires('mild', 'si');
        expect(en, isNotEmpty);
        expect(si, isNotEmpty);
        expect(en, isNot(equals(si)));
      },
    );

    test('questionnaires() handles all DASS-21 severity levels in English', () {
      for (final key in [
        'normal',
        'mild',
        'moderate',
        'severe',
        'extremelySevere',
      ]) {
        final val = LocalizationService.instance.questionnaires(key, 'en');
        expect(val, isNotEmpty, reason: 'Missing key: $key');
      }
    });

    test('questionnaires() handles MAAS classification keys', () {
      for (final key in ['highLevelMindfulness', 'lowLevelMindfulness']) {
        final val = LocalizationService.instance.questionnaires(key, 'en');
        expect(val, isNotEmpty, reason: 'Missing key: $key');
      }
    });

    test('validators() returns a non-empty string for emailRequired', () {
      final val = LocalizationService.instance.validators(
        'emailRequired',
        'en',
      );
      expect(val, isNotEmpty);
    });

    group('after reset()', () {
      setUp(() async {
        LocalizationService.instance.reset();
        await LocalizationService.instance.loadTranslations();
      });

      test('common() still returns expected values after reload', () {
        final val = LocalizationService.instance.common('appName', 'en');
        expect(val, isNotEmpty);
      });
    });
  });
}
