import '../constants/app_constants.dart';

class UserValidator {
  static final _letter = RegExp(r'\p{L}', unicode: true);

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
}
