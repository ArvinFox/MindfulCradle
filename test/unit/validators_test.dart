import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/services/localization_service.dart';
import 'package:mamamind/utils/validators.dart';

/// Loads translations once for the whole test suite so that validators
/// return real error strings rather than raw key names.
Future<void> _loadTranslations() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  LocalizationService.instance.reset();
  await LocalizationService.instance.loadTranslations();
}

void main() {
  setUpAll(_loadTranslations);

  // ── Email validation ───────────────────────────────────────────────────
  group('Validators.validateEmail()', () {
    test('returns error for null input', () {
      expect(Validators.validateEmail(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('returns error when @ is missing', () {
      expect(Validators.validateEmail('invalidemail.com'), isNotNull);
    });

    test('returns error for email missing domain', () {
      expect(Validators.validateEmail('user@'), isNotNull);
    });

    test('returns error for email missing TLD', () {
      expect(Validators.validateEmail('user@domain'), isNotNull);
    });

    test('returns null for a valid email', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
    });

    test('returns null for email with subdomain', () {
      expect(Validators.validateEmail('user@mail.example.com'), isNull);
    });

    test('returns null for email with dots in local part', () {
      expect(Validators.validateEmail('first.last@example.com'), isNull);
    });
  });

  // ── Password validation ────────────────────────────────────────────────
  group('Validators.validatePassword()', () {
    test('returns error for null input', () {
      expect(Validators.validatePassword(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('returns error for password shorter than 6 characters', () {
      expect(Validators.validatePassword('abc'), isNotNull);
      expect(Validators.validatePassword('12345'), isNotNull);
    });

    test('returns null for exactly 6-character password', () {
      expect(Validators.validatePassword('abcdef'), isNull);
    });

    test('returns null for a strong password', () {
      expect(Validators.validatePassword('Str0ng!Pass'), isNull);
    });
  });

  // ── Name validation ────────────────────────────────────────────────────
  group('Validators.validateName()', () {
    test('returns error for null input', () {
      expect(Validators.validateName(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.validateName(''), isNotNull);
    });

    test('returns null for a non-empty name', () {
      expect(Validators.validateName('Kasuni Perera'), isNull);
    });

    test('returns null for a single-word name', () {
      expect(Validators.validateName('Kasuni'), isNull);
    });
  });

  // ── Confirm password validation ────────────────────────────────────────
  group('Validators.validateConfirmPassword()', () {
    test('returns error when passwords do not match', () {
      expect(
        Validators.validateConfirmPassword('password123', 'differentPass'),
        isNotNull,
      );
    });

    test('returns error when confirm is empty', () {
      expect(Validators.validateConfirmPassword('password123', ''), isNotNull);
    });

    test('returns error when confirm is null', () {
      expect(
        Validators.validateConfirmPassword('password123', null),
        isNotNull,
      );
    });

    test('returns null when passwords match exactly', () {
      expect(
        Validators.validateConfirmPassword('Str0ng!Pass', 'Str0ng!Pass'),
        isNull,
      );
    });

    test('returns error for case mismatch', () {
      // Passwords are case-sensitive.
      expect(
        Validators.validateConfirmPassword('Password', 'password'),
        isNotNull,
      );
    });
  });

  // ── Localized variants ─────────────────────────────────────────────────
  group('Localized validators return the correct language variant', () {
    test('validateEmailWithLang returns EN error for empty email', () {
      final error = Validators.validateEmailWithLang('', 'en');
      expect(error, isNotNull);
    });

    test('validateEmailWithLang returns SI error for empty email', () {
      final error = Validators.validateEmailWithLang('', 'si');
      expect(error, isNotNull);
      // Sinhala and English errors should differ.
      final enError = Validators.validateEmailWithLang('', 'en');
      expect(error, isNot(equals(enError)));
    });

    test('validatePasswordWithLang EN returns error for short password', () {
      expect(Validators.validatePasswordWithLang('abc', 'en'), isNotNull);
    });

    test('validatePasswordWithLang SI returns error for short password', () {
      expect(Validators.validatePasswordWithLang('abc', 'si'), isNotNull);
    });
  });
}
