/// Values used by business rules. Keep them here, not inline in the code.
class AppConstants {
  /// A task with less time than this left (and not overdue) is "At Risk".
  static const Duration atRiskWindow = Duration(hours: 48);

  static const int titleMinLength = 3;
  static const int titleMaxLength = 60;
  static const int descriptionMaxLength = 300;
  static const int userNameMinLength = 2;
  static const int userNameMaxLength = 30;
}
