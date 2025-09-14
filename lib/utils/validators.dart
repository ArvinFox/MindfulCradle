class Validators {
  // Check if email is valid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  // Check if password is valid (at least 6 characters)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Check if full name is entered
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  // Check if confirm password matches password
  static String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'Confirm your password';
    }
    if (password != confirm) {
      return 'Passwords do not match';
    }
    return null;
  }
}
