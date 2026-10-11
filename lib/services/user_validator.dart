import '../constants/app_constants.dart';

class UserValidator {
  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _digit = RegExp(r'[0-9]');
  // something@something.something, no spaces
  static final _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? name(
    String? value, {
    Iterable<String> existingNames = const [],
  }) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Please enter a name.';
    }
    if (name.length < AppConstants.userNameMinLength) {
      return 'Name must be at least '
          '${AppConstants.userNameMinLength} characters.';
    }
    if (name.length > AppConstants.userNameMaxLength) {
      return 'Name must be at most '
          '${AppConstants.userNameMaxLength} characters.';
    }
    if (!_letter.hasMatch(name)) {
      return 'Name must contain at least one letter.';
    }
    final lowerName = name.toLowerCase();
    final isTaken = existingNames.any(
      (existing) => existing.trim().toLowerCase() == lowerName,
    );
    if (isTaken) {
      return 'A team member called "$name" already exists.';
    }
    return null;
  }

  /// Leave [existingEmails] empty on Sign In, where the email should exist.
  static String? email(
    String? value, {
    Iterable<String> existingEmails = const [],
  }) {
    final email = value?.trim().toLowerCase() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email.';
    }
    if (!_emailShape.hasMatch(email)) {
      return 'Enter a valid email, like name@example.com.';
    }
    final isTaken = existingEmails.any(
      (existing) => existing.trim().toLowerCase() == email,
    );
    if (isTaken) {
      return 'An account with this email already exists.';
    }
    return null;
  }

  /// Rules for a new password (Sign Up). Sign In only checks it isn't empty.
  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Please enter a password.';
    }
    if (password.length < AppConstants.passwordMinLength) {
      return 'Password must be at least '
          '${AppConstants.passwordMinLength} characters.';
    }
    if (!_letter.hasMatch(password) || !_digit.hasMatch(password)) {
      return 'Password must include a letter and a number.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? signInPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }
    return null;
  }
}
