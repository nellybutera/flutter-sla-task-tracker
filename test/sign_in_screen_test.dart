import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/models/user.dart';
import 'package:sla_task_tracker/routes.dart';
import 'package:sla_task_tracker/screens/sign_in_screen.dart';
import 'package:sla_task_tracker/services/auth_service.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

/// Fails the first load, then behaves normally, to test the retry button.
class _FlakyStorage extends StorageService {
  bool _hasFailed = false;

  @override
  Future<User?> loadCurrentUser() {
    if (!_hasFailed) {
      _hasFailed = true;
      return Future.error(Exception('disk unavailable'));
    }
    return super.loadCurrentUser();
  }
}

void main() {
  const dashboardMarker = 'Dashboard page';
  final emailField = find.byKey(const Key('emailField'));
  final passwordField = find.byKey(const Key('passwordField'));
  final signInButton = find.widgetWithText(FilledButton, 'Sign in');

  Future<void> pumpSignIn(
    WidgetTester tester, {
    StorageService? storage,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SignInScreen(storage: storage),
        routes: {
          Routes.dashboard: (_) => const Scaffold(body: Text(dashboardMarker)),
          Routes.signUp: (_) => const Scaffold(body: Text('Sign up page')),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> signIn(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await tester.enterText(emailField, email);
    await tester.enterText(passwordField, password);
    await tester.tap(signInButton);
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('empty fields show an error under each one', (tester) async {
    await pumpSignIn(tester);

    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
    expect(find.text(dashboardMarker), findsNothing);
  });

  testWidgets('an email without a proper shape shows an error', (tester) async {
    await pumpSignIn(tester);

    await signIn(tester, 'alice@demo', 'whatever1');

    expect(
      find.text('Enter a valid email, like name@example.com.'),
      findsOneWidget,
    );
  });

  testWidgets('a wrong password shows a clear error and stays here', (
    tester,
  ) async {
    await pumpSignIn(tester);

    await signIn(tester, 'alice@demo.com', 'Wrong1234');

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(find.text(dashboardMarker), findsNothing);
    expect(await StorageService().loadCurrentUser(), isNull);
  });

  testWidgets('an unknown email shows the same error as a wrong password', (
    tester,
  ) async {
    await pumpSignIn(tester);

    await signIn(tester, 'nobody@demo.com', AuthService.demoPassword);

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('typing again clears the sign in error', (tester) async {
    await pumpSignIn(tester);
    await signIn(tester, 'alice@demo.com', 'Wrong1234');

    await tester.enterText(passwordField, 'Wrong12345');
    await tester.pump();

    expect(find.text('Email or password is incorrect.'), findsNothing);
  });

  testWidgets('the right email and password open the dashboard', (
    tester,
  ) async {
    await pumpSignIn(tester);

    await signIn(tester, 'alice@demo.com', AuthService.demoPassword);

    expect(find.text(dashboardMarker), findsOneWidget);
    expect((await StorageService().loadCurrentUser())?.name, 'Alice');
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse, reason: 'no way back to Sign In');
  });

  testWidgets('email ignores capitals and spaces around it', (tester) async {
    await pumpSignIn(tester);

    await signIn(tester, '  Alice@Demo.com ', AuthService.demoPassword);

    expect(find.text(dashboardMarker), findsOneWidget);
  });

  testWidgets('the password is hidden until the eye button is tapped', (
    tester,
  ) async {
    await pumpSignIn(tester);
    bool isHidden() => tester
        .widget<EditableText>(
          find.descendant(
            of: passwordField,
            matching: find.byType(EditableText),
          ),
        )
        .obscureText;

    expect(isHidden(), isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    expect(isHidden(), isFalse);
  });

  testWidgets('Create one opens Sign Up', (tester) async {
    await pumpSignIn(tester);

    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();

    expect(find.text('Sign up page'), findsOneWidget);
  });

  testWidgets('a saved user skips sign in on the next launch', (tester) async {
    SharedPreferences.setMockInitialValues({'currentUserId': 'u2'});

    await pumpSignIn(tester);

    expect(find.text(dashboardMarker), findsOneWidget);
  });

  testWidgets('a storage error shows a message and Try again recovers', (
    tester,
  ) async {
    await pumpSignIn(tester, storage: _FlakyStorage());

    expect(
      find.text('Could not open the app. Please try again.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(emailField, findsOneWidget);
  });
}
