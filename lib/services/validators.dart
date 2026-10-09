import '../constants/app_constants.dart';

/// Validation rules for creating and editing tasks.
///
/// Each method returns:
/// - null when the value is valid
/// - a clear error message when the value is invalid
class Validators {
  static String? title(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Title is required.';
    }

    if (text.length < AppConstants.titleMinLength) {
      return 'Title must be at least '
          '${AppConstants.titleMinLength} characters.';
    }

    if (text.length > AppConstants.titleMaxLength) {
      return 'Title must be at most '
          '${AppConstants.titleMaxLength} characters.';
    }

    return null;
  }

  static String? description(String? value) {
    final text = value?.trim() ?? '';

    if (text.length > AppConstants.descriptionMaxLength) {
      return 'Description must be at most '
          '${AppConstants.descriptionMaxLength} characters.';
    }

    return null;
  }

  static String? assignee(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select an assignee.';
    }

    return null;
  }

  static String? deadline(
    DateTime? value, {
    required bool isNewTask,
    DateTime? now,
  }) {
    if (value == null) {
      return 'Please select a deadline.';
    }

    // Existing tasks may keep their old deadline when being edited.
    if (!isNewTask) {
      return null;
    }

    final currentTime = now ?? DateTime.now();

    if (value.isBefore(currentTime)) {
      return 'Deadline cannot be in the past.';
    }

    return null;
  }
}
