import '../services/localization_service.dart';

class Validators {
  // Check if email is valid
  static String? validateEmail(String? value) {
    return _validateEmail(value, lang: 'en');
  }

  static String? validateEmailLocalized(
    String? value, {
    required bool isSinhala,
  }) {
    return _validateEmail(value, lang: isSinhala ? 'si' : 'en');
  }

  // New method using language code directly
  static String? validateEmailWithLang(String? value, String lang) {
    return _validateEmail(value, lang: lang);
  }

  // Check if password is valid (at least 6 characters)
  static String? validatePassword(String? value) {
    return _validatePassword(value, lang: 'en');
  }

  static String? validatePasswordLocalized(
    String? value, {
    required bool isSinhala,
  }) {
    return _validatePassword(value, lang: isSinhala ? 'si' : 'en');
  }

  static String? validatePasswordWithLang(String? value, String lang) {
    return _validatePassword(value, lang: lang);
  }

  // Check if full name is entered
  static String? validateName(String? value) {
    return _validateName(value, lang: 'en');
  }

  static String? validateNameLocalized(
    String? value, {
    required bool isSinhala,
  }) {
    return _validateName(value, lang: isSinhala ? 'si' : 'en');
  }

  static String? validateNameWithLang(String? value, String lang) {
    return _validateName(value, lang: lang);
  }

  // Check if confirm password matches password
  static String? validateConfirmPassword(String? password, String? confirm) {
    return _validateConfirmPassword(password, confirm, lang: 'en');
  }

  static String? validateConfirmPasswordLocalized(
    String? password,
    String? confirm, {
    required bool isSinhala,
  }) {
    return _validateConfirmPassword(
      password,
      confirm,
      lang: isSinhala ? 'si' : 'en',
    );
  }

  static String? validateConfirmPasswordWithLang(
    String? password,
    String? confirm,
    String lang,
  ) {
    return _validateConfirmPassword(password, confirm, lang: lang);
  }

  // Internal validation methods using LocalizationService
  static String? _validateEmail(String? value, {required String lang}) {
    final loc = LocalizationService.instance;

    if (value == null || value.isEmpty) {
      return loc.validators('emailRequired', lang);
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return loc.validators('emailInvalid', lang);
    }
    return null;
  }

  static String? _validatePassword(String? value, {required String lang}) {
    final loc = LocalizationService.instance;

    if (value == null || value.isEmpty) {
      return loc.validators('passwordRequired', lang);
    }
    if (value.length < 6) {
      return loc.validators('passwordTooShort', lang);
    }
    return null;
  }

  static String? _validateName(String? value, {required String lang}) {
    final loc = LocalizationService.instance;

    if (value == null || value.isEmpty) {
      return loc.validators('nameRequired', lang);
    }
    return null;
  }

  static String? _validateConfirmPassword(
    String? password,
    String? confirm, {
    required String lang,
  }) {
    final loc = LocalizationService.instance;

    if (confirm == null || confirm.isEmpty) {
      return loc.validators('confirmPasswordRequired', lang);
    }
    if (password != confirm) {
      return loc.validators('passwordsDoNotMatch', lang);
    }
    return null;
  }
}
