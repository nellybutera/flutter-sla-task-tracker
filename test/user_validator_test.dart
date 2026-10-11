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

  group('UserValidator.email', () {
    test('rejects an empty email', () {
      expect(UserValidator.email(null), 'Please enter your email.');
      expect(UserValidator.email('  '), 'Please enter your email.');
    });

    test('rejects emails without the name@domain.ext shape', () {
      const message = 'Enter a valid email, like name@example.com.';
      expect(UserValidator.email('belyse'), message);
      expect(UserValidator.email('belyse@example'), message);
      expect(UserValidator.email('@example.com'), message);
      expect(UserValidator.email('bel yse@example.com'), message);
    });

    test('accepts a normal email, ignoring spaces and capitals', () {
      expect(UserValidator.email(' Belyse@Example.com '), isNull);
    });

    test('rejects an email that is already taken, ignoring case', () {
      final result = UserValidator.email(
        'ALICE@demo.com',
        existingEmails: const ['alice@demo.com'],
      );

      expect(result, 'An account with this email already exists.');
    });
  });

  group('UserValidator.newPassword', () {
    test('rejects an empty password', () {
      expect(UserValidator.newPassword(''), 'Please enter a password.');
    });

    test('rejects a password one character too short', () {
      final tooShort = '${'a' * (AppConstants.passwordMinLength - 2)}1';

      expect(UserValidator.newPassword(tooShort), contains('at least'));
    });

    test('accepts exactly the minimum length with a letter and a number', () {
      final shortest = '${'a' * (AppConstants.passwordMinLength - 1)}1';

      expect(UserValidator.newPassword(shortest), isNull);
    });

    test('needs both a letter and a number', () {
      const message = 'Password must include a letter and a number.';
      expect(UserValidator.newPassword('onlyletters'), message);
      expect(UserValidator.newPassword('12345678'), message);
    });
  });

  group('UserValidator.confirmPassword', () {
    test('asks for the password again when empty', () {
      expect(
        UserValidator.confirmPassword('', 'Secret123'),
        'Please confirm your password.',
      );
    });

    test('must match exactly', () {
      expect(
        UserValidator.confirmPassword('secret123', 'Secret123'),
        'Passwords do not match.',
      );
      expect(UserValidator.confirmPassword('Secret123', 'Secret123'), isNull);
    });
  });

  group('UserValidator.signInPassword', () {
    test('only checks that something was typed', () {
      expect(UserValidator.signInPassword(''), 'Please enter your password.');
      expect(UserValidator.signInPassword('x'), isNull);
    });
  });
}
