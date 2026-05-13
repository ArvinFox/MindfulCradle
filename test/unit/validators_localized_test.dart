import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/services/localization_service.dart';
import 'package:mamamind/utils/validators.dart';

Future<void> _loadTranslations() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  LocalizationService.instance.reset();
  await LocalizationService.instance.loadTranslations();
}

void main() {
  setUpAll(_loadTranslations);

  // ── validateEmailLocalized() ──────────────────────────────────────────────
  group('Validators.validateEmailLocalized()', () {
    test('returns error for empty email in English (isSinhala=false)', () {
      expect(
        Validators.validateEmailLocalized('', isSinhala: false),
        isNotNull,
      );
    });

    test('returns error for empty email in Sinhala (isSinhala=true)', () {
      expect(Validators.validateEmailLocalized('', isSinhala: true), isNotNull);
    });

    test('EN and SI error messages differ for empty email', () {
      final en = Validators.validateEmailLocalized('', isSinhala: false);
      final si = Validators.validateEmailLocalized('', isSinhala: true);
      expect(en, isNot(equals(si)));
    });

    test('returns error for invalid email format in English', () {
      expect(
        Validators.validateEmailLocalized('notanemail', isSinhala: false),
        isNotNull,
      );
    });

    test('returns error for invalid email format in Sinhala', () {
      expect(
        Validators.validateEmailLocalized('notanemail', isSinhala: true),
        isNotNull,
      );
    });

    test('returns null for valid email in English', () {
      expect(
        Validators.validateEmailLocalized('user@example.com', isSinhala: false),
        isNull,
      );
    });

    test('returns null for valid email in Sinhala', () {
      expect(
        Validators.validateEmailLocalized('user@example.com', isSinhala: true),
        isNull,
      );
    });
  });

  // ── validatePasswordLocalized() ───────────────────────────────────────────
  group('Validators.validatePasswordLocalized()', () {
    test('returns error for null password in English', () {
      expect(
        Validators.validatePasswordLocalized(null, isSinhala: false),
        isNotNull,
      );
    });

    test('returns error for null password in Sinhala', () {
      expect(
        Validators.validatePasswordLocalized(null, isSinhala: true),
        isNotNull,
      );
    });

    test('EN and SI error messages differ for null password', () {
      final en = Validators.validatePasswordLocalized(null, isSinhala: false);
      final si = Validators.validatePasswordLocalized(null, isSinhala: true);
      expect(en, isNot(equals(si)));
    });

    test('returns error for password shorter than 6 chars in English', () {
      expect(
        Validators.validatePasswordLocalized('abc', isSinhala: false),
        isNotNull,
      );
    });

    test('returns error for password shorter than 6 chars in Sinhala', () {
      expect(
        Validators.validatePasswordLocalized('abc', isSinhala: true),
        isNotNull,
      );
    });

    test('returns null for valid 6-char password in English', () {
      expect(
        Validators.validatePasswordLocalized('abcdef', isSinhala: false),
        isNull,
      );
    });

    test('returns null for valid 6-char password in Sinhala', () {
      expect(
        Validators.validatePasswordLocalized('abcdef', isSinhala: true),
        isNull,
      );
    });

    test('returns null for strong password in Sinhala mode', () {
      expect(
        Validators.validatePasswordLocalized('Str0ng!Pass', isSinhala: true),
        isNull,
      );
    });
  });

  // ── validateNameLocalized() ───────────────────────────────────────────────
  group('Validators.validateNameLocalized()', () {
    test('returns error for null name in English', () {
      expect(
        Validators.validateNameLocalized(null, isSinhala: false),
        isNotNull,
      );
    });

    test('returns error for null name in Sinhala', () {
      expect(
        Validators.validateNameLocalized(null, isSinhala: true),
        isNotNull,
      );
    });

    test('returns error for empty name in English', () {
      expect(Validators.validateNameLocalized('', isSinhala: false), isNotNull);
    });

    test('returns error for empty name in Sinhala', () {
      expect(Validators.validateNameLocalized('', isSinhala: true), isNotNull);
    });

    test('EN and SI name error messages differ', () {
      final en = Validators.validateNameLocalized(null, isSinhala: false);
      final si = Validators.validateNameLocalized(null, isSinhala: true);
      expect(en, isNot(equals(si)));
    });

    test('returns null for valid name in English', () {
      expect(
        Validators.validateNameLocalized('Kasuni Perera', isSinhala: false),
        isNull,
      );
    });

    test('returns null for valid name in Sinhala', () {
      expect(
        Validators.validateNameLocalized('Kasuni Perera', isSinhala: true),
        isNull,
      );
    });
  });

  // ── validateNameWithLang() ────────────────────────────────────────────────
  group('Validators.validateNameWithLang()', () {
    test('returns error for null name with lang="en"', () {
      expect(Validators.validateNameWithLang(null, 'en'), isNotNull);
    });

    test('returns error for null name with lang="si"', () {
      expect(Validators.validateNameWithLang(null, 'si'), isNotNull);
    });

    test('returns error for empty string with lang="en"', () {
      expect(Validators.validateNameWithLang('', 'en'), isNotNull);
    });

    test('returns error for empty string with lang="si"', () {
      expect(Validators.validateNameWithLang('', 'si'), isNotNull);
    });

    test('returns null for valid name with lang="en"', () {
      expect(Validators.validateNameWithLang('Amali', 'en'), isNull);
    });

    test('returns null for valid name with lang="si"', () {
      expect(Validators.validateNameWithLang('Amali', 'si'), isNull);
    });

    test('EN and SI errors differ', () {
      final en = Validators.validateNameWithLang(null, 'en');
      final si = Validators.validateNameWithLang(null, 'si');
      expect(en, isNot(equals(si)));
    });
  });

  // ── validateConfirmPasswordLocalized() ───────────────────────────────────
  group('Validators.validateConfirmPasswordLocalized()', () {
    test('returns error when passwords do not match in English', () {
      expect(
        Validators.validateConfirmPasswordLocalized(
          'pass1',
          'pass2',
          isSinhala: false,
        ),
        isNotNull,
      );
    });

    test('returns error when passwords do not match in Sinhala', () {
      expect(
        Validators.validateConfirmPasswordLocalized(
          'pass1',
          'pass2',
          isSinhala: true,
        ),
        isNotNull,
      );
    });

    test('returns null when passwords match in English', () {
      expect(
        Validators.validateConfirmPasswordLocalized(
          'Str0ng!',
          'Str0ng!',
          isSinhala: false,
        ),
        isNull,
      );
    });

    test('returns null when passwords match in Sinhala', () {
      expect(
        Validators.validateConfirmPasswordLocalized(
          'Str0ng!',
          'Str0ng!',
          isSinhala: true,
        ),
        isNull,
      );
    });

    test('returns error when confirm is empty in English', () {
      expect(
        Validators.validateConfirmPasswordLocalized(
          'password',
          '',
          isSinhala: false,
        ),
        isNotNull,
      );
    });

    test('returns error when confirm is empty in Sinhala', () {
      expect(
        Validators.validateConfirmPasswordLocalized(
          'password',
          '',
          isSinhala: true,
        ),
        isNotNull,
      );
    });
  });

  // ── validateConfirmPasswordWithLang() ────────────────────────────────────
  group('Validators.validateConfirmPasswordWithLang()', () {
    test('returns error when passwords differ with lang="en"', () {
      expect(
        Validators.validateConfirmPasswordWithLang('abc', 'xyz', 'en'),
        isNotNull,
      );
    });

    test('returns error when passwords differ with lang="si"', () {
      expect(
        Validators.validateConfirmPasswordWithLang('abc', 'xyz', 'si'),
        isNotNull,
      );
    });

    test('returns null when passwords match with lang="en"', () {
      expect(
        Validators.validateConfirmPasswordWithLang('match', 'match', 'en'),
        isNull,
      );
    });

    test('returns null when passwords match with lang="si"', () {
      expect(
        Validators.validateConfirmPasswordWithLang('match', 'match', 'si'),
        isNull,
      );
    });

    test('returns error when confirm is null with lang="en"', () {
      expect(
        Validators.validateConfirmPasswordWithLang('password', null, 'en'),
        isNotNull,
      );
    });

    test('EN and SI mismatch errors differ', () {
      final en = Validators.validateConfirmPasswordWithLang('a', 'b', 'en');
      final si = Validators.validateConfirmPasswordWithLang('a', 'b', 'si');
      expect(en, isNot(equals(si)));
    });
  });
}
