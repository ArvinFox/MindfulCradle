class Validators {
  // Check if email is valid
  static String? validateEmail(String? value) {
    return _validateEmail(value, isSinhala: false);
  }

  static String? validateEmailLocalized(
    String? value, {
    required bool isSinhala,
  }) {
    return _validateEmail(value, isSinhala: isSinhala);
  }

  // Check if password is valid (at least 6 characters)
  static String? validatePassword(String? value) {
    return _validatePassword(value, isSinhala: false);
  }

  static String? validatePasswordLocalized(
    String? value, {
    required bool isSinhala,
  }) {
    return _validatePassword(value, isSinhala: isSinhala);
  }

  // Check if full name is entered
  static String? validateName(String? value) {
    return _validateName(value, isSinhala: false);
  }

  static String? validateNameLocalized(
    String? value, {
    required bool isSinhala,
  }) {
    return _validateName(value, isSinhala: isSinhala);
  }

  // Check if confirm password matches password
  static String? validateConfirmPassword(String? password, String? confirm) {
    return _validateConfirmPassword(password, confirm, isSinhala: false);
  }

  static String? validateConfirmPasswordLocalized(
    String? password,
    String? confirm, {
    required bool isSinhala,
  }) {
    return _validateConfirmPassword(password, confirm, isSinhala: isSinhala);
  }

  static String? _validateEmail(String? value, {required bool isSinhala}) {
    if (value == null || value.isEmpty) {
      return isSinhala ? 'ඊමේල් අවශ්‍යයි' : 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return isSinhala
          ? 'වලංගු ඊමේල් ලිපිනයක් ඇතුළත් කරන්න'
          : 'Enter a valid email';
    }
    return null;
  }

  static String? _validatePassword(String? value, {required bool isSinhala}) {
    if (value == null || value.isEmpty) {
      return isSinhala ? 'මුරපදය අවශ්‍යයි' : 'Password is required';
    }
    if (value.length < 6) {
      return isSinhala
          ? 'මුරපදය අක්ෂර 6 කට වැඩි විය යුතුයි'
          : 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? _validateName(String? value, {required bool isSinhala}) {
    if (value == null || value.isEmpty) {
      return isSinhala ? 'සම්පූර්ණ නම අවශ්‍යයි' : 'Full name is required';
    }
    return null;
  }

  static String? _validateConfirmPassword(
    String? password,
    String? confirm, {
    required bool isSinhala,
  }) {
    if (confirm == null || confirm.isEmpty) {
      return isSinhala ? 'මුරපදය තහවුරු කරන්න' : 'Confirm your password';
    }
    if (password != confirm) {
      return isSinhala ? 'මුරපද නොගැලපේ' : 'Passwords do not match';
    }
    return null;
  }
}
