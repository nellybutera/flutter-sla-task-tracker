import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker/constants/app_constants.dart';
import 'package:sla_task_tracker/services/user_validator.dart';

void main() {
  group('UserValidator.name', () {
    test('accepts a normal name', () {
      expect(UserValidator.name('Belyse'), isNull);
    });

    test('rejects null, empty and whitespace-only input', () {
      expect(UserValidator.name(null), 'Please enter a name.');
      expect(UserValidator.name(''), 'Please enter a name.');
      expect(UserValidator.name('   '), 'Please enter a name.');
    });

    test('rejects a name shorter than the minimum', () {
      final tooShort = 'a' * (AppConstants.userNameMinLength - 1);

      final result = UserValidator.name(tooShort);

      expect(result, contains('at least ${AppConstants.userNameMinLength}'));
    });

    test('accepts a name exactly at the minimum length', () {
      final shortest = 'a' * AppConstants.userNameMinLength;

      expect(UserValidator.name(shortest), isNull);
    });

    test('accepts a name exactly at the maximum length', () {
      final longest = 'a' * AppConstants.userNameMaxLength;

      expect(UserValidator.name(longest), isNull);
    });

    test('rejects a name longer than the maximum', () {
      final tooLong = 'a' * (AppConstants.userNameMaxLength + 1);

      final result = UserValidator.name(tooLong);

      expect(result, contains('at most ${AppConstants.userNameMaxLength}'));
    });

    test('ignores surrounding spaces when checking length', () {
      final padded = '  ${'a' * (AppConstants.userNameMinLength - 1)}  ';

      expect(UserValidator.name(padded), isNotNull);
    });

    test('rejects a name without any letters', () {
      expect(
        UserValidator.name('123'),
        'Name must contain at least one letter.',
      );
    });

    test('accepts letters outside the English alphabet', () {
      expect(UserValidator.name('Zoë'), isNull);
    });

    test('rejects a name already in the team, ignoring case', () {
      const existing = ['Alice', 'Brian'];

      final result = UserValidator.name(' alice ', existingNames: existing);

      expect(result, 'A team member called "alice" already exists.');
    });

    test('accepts a new name when other names exist', () {
      const existing = ['Alice', 'Brian'];

      expect(UserValidator.name('Chloe', existingNames: existing), isNull);
    });
  });
}
