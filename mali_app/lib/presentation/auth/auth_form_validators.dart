class AuthFormValidators {
  const AuthFormValidators._();

  static const int minPasswordLength = 8;

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? name(String? value, {required bool touched}) {
    if (!touched) return null;

    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter your name';
    }
    return null;
  }

  static String? email(String? value, {required bool touched}) {
    if (!touched) return null;

    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter your email address';
    }

    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? phone(String? value, {required bool touched}) {
    if (!touched) return null;

    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter your phone number';
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 8) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  static String? password(String? value, {required bool touched}) {
    if (!touched) return null;

    final trimmed = value ?? '';
    if (trimmed.isEmpty) {
      return 'Enter a password';
    }

    if (trimmed.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }

    return null;
  }

  static String? confirmPassword(
    String? value, {
    required bool touched,
    required String password,
  }) {
    if (!touched) return null;

    if (value == null || value.isEmpty) {
      return 'Confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  static String? loginContact(String? value, {required bool touched}) {
    if (!touched) return null;

    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter your email or phone number';
    }

    if (trimmed.contains('@')) {
      return email(value, touched: true);
    }

    return phone(value, touched: true);
  }

  static String? loginPassword(String? value, {required bool touched}) {
    if (!touched) return null;

    if (value == null || value.isEmpty) {
      return 'Enter your password';
    }

    return null;
  }

  static bool looksLikeEmail(String value) => value.trim().contains('@');
}
