import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/routes.dart';
import 'package:sla_task_tracker/screens/sign_up_screen.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

void main() {
  const dashboardMarker = 'Dashboard page';
  final nameField = find.byKey(const Key('nameField'));
  final emailField = find.byKey(const Key('emailField'));
  final passwordField = find.byKey(const Key('passwordField'));
  final confirmField = find.byKey(const Key('confirmField'));
  final createButton = find.widgetWithText(FilledButton, 'Create account');

  Future<void> pumpSignUp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: const SignUpScreen(),
        routes: {
          Routes.dashboard: (_) => const Scaffold(body: Text(dashboardMarker)),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    String name = 'Belyse Intwaza',
    String email = 'belyse@example.com',
    String password = 'Secret123',
    String? confirm,
  }) async {
    await tester.enterText(nameField, name);
    await tester.enterText(emailField, email);
    await tester.enterText(passwordField, password);
    await tester.enterText(confirmField, confirm ?? password);
    await tester.tap(createButton);
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('an empty form shows a message for every field', (tester) async {
    await pumpSignUp(tester);

    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter a name.'), findsOneWidget);
    expect(find.text('Please enter your email.'), findsOneWidget);
    expect(find.text('Please enter a password.'), findsOneWidget);
    expect(find.text('Please confirm your password.'), findsOneWidget);
  });

  testWidgets('a bad email shows an error', (tester) async {
    await pumpSignUp(tester);

    await fillAndSubmit(tester, email: 'belyse@example');

    expect(
      find.text('Enter a valid email, like name@example.com.'),
      findsOneWidget,
    );
    expect(find.text(dashboardMarker), findsNothing);
  });

  testWidgets('an email that already has an account shows an error', (
    tester,
  ) async {
    await pumpSignUp(tester);

    await fillAndSubmit(tester, email: 'Alice@demo.com');

    expect(
      find.text('An account with this email already exists.'),
      findsOneWidget,
    );
  });

  testWidgets('a short password shows an error', (tester) async {
    await pumpSignUp(tester);

    await fillAndSubmit(tester, password: 'Abc123');

    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
    );
  });

  testWidgets('a password without a number shows an error', (tester) async {
    await pumpSignUp(tester);

    await fillAndSubmit(tester, password: 'onlyletters');

    expect(
      find.text('Password must include a letter and a number.'),
      findsOneWidget,
    );
  });

  testWidgets('passwords that do not match show an error', (tester) async {
    await pumpSignUp(tester);

    await fillAndSubmit(tester, confirm: 'Secret124');

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('a valid form creates the account and opens the dashboard', (
    tester,
  ) async {
    await pumpSignUp(tester);

    await fillAndSubmit(tester, email: ' Belyse@Example.com ');

    expect(find.text(dashboardMarker), findsOneWidget);
    final current = await StorageService().loadCurrentUser();
    expect(current?.name, 'Belyse Intwaza');
    expect(current?.email, 'belyse@example.com');
  });

  testWidgets('Sign in goes back to the Sign In screen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Sign in page'))),
    );
    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(MaterialPageRoute<void>(builder: (_) => const SignUpScreen())),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(TextButton, 'Sign in'));
    await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in page'), findsOneWidget);
  });
}
