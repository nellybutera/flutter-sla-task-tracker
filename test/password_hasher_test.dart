import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker/services/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('accepts the right password and rejects others', () {
      final credential = PasswordHasher.create('Secret123');

      expect(PasswordHasher.verify('Secret123', credential), isTrue);
      expect(PasswordHasher.verify('secret123', credential), isFalse);
      expect(PasswordHasher.verify('', credential), isFalse);
    });

    test('the same password gets a different salt and hash each time', () {
      final first = PasswordHasher.create('Secret123');
      final second = PasswordHasher.create('Secret123');

      expect(first.salt, isNot(second.salt));
      expect(first.hash, isNot(second.hash));
    });

    test('the same salt gives the same hash', () {
      final first = PasswordHasher.create('Secret123', random: Random(7));
      final second = PasswordHasher.create('Secret123', random: Random(7));

      expect(first.hash, second.hash);
    });

    test('the stored hash does not contain the password', () {
      final credential = PasswordHasher.create('Secret123');

      expect(credential.hash, isNot(contains('Secret123')));
      expect(credential.hash, hasLength(64));
    });
  });
}
