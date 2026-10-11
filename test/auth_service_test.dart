import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/services/auth_service.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AuthService.signIn', () {
    test('a demo account signs in with the demo password', () async {
      final user = await AuthService().signIn(
        email: 'brian@demo.com',
        password: AuthService.demoPassword,
      );

      expect(user.name, 'Brian');
      expect((await StorageService().loadCurrentUser())?.id, 'u2');
    });

    test('a wrong password and an unknown email give the same error', () {
      final auth = AuthService();

      expect(
        auth.signIn(email: 'brian@demo.com', password: 'Wrong1234'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Email or password is incorrect.',
          ),
        ),
      );
      expect(
        auth.signIn(
          email: 'ghost@demo.com',
          password: AuthService.demoPassword,
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Email or password is incorrect.',
          ),
        ),
      );
    });

    test('works on a phone that saved users before accounts existed', () async {
      SharedPreferences.setMockInitialValues({
        'users': jsonEncode([
          {'id': 'u1', 'name': 'Alice', 'role': 'Project Lead'},
        ]),
      });

      final user = await AuthService().signIn(
        email: 'alice@demo.com',
        password: AuthService.demoPassword,
      );

      expect(user.id, 'u1');
    });
  });

  group('AuthService.signUp', () {
    test(
      'creates the user, signs them in, and they can sign in again',
      () async {
        final auth = AuthService();

        final created = await auth.signUp(
          name: ' Belyse ',
          email: ' Belyse@Example.com ',
          role: 'Developer',
          password: 'Secret123',
        );
        await StorageService().clearCurrentUser();
        final signedIn = await auth.signIn(
          email: 'belyse@example.com',
          password: 'Secret123',
        );

        expect(created.name, 'Belyse');
        expect(created.email, 'belyse@example.com');
        expect(signedIn.id, created.id);
      },
    );

    test('refuses an email that already has an account', () async {
      await expectLater(
        AuthService().signUp(
          name: 'Another Alice',
          email: 'ALICE@demo.com',
          role: 'Developer',
          password: 'Secret123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('never stores the password itself', () async {
      await AuthService().signUp(
        name: 'Belyse',
        email: 'belyse@example.com',
        role: 'Developer',
        password: 'Secret123',
      );

      final prefs = await SharedPreferences.getInstance();
      final everything = prefs
          .getKeys()
          .map((key) => '${prefs.get(key)}')
          .join();
      expect(everything, isNot(contains('Secret123')));
      expect(everything, isNot(contains(AuthService.demoPassword)));
    });
  });
}
