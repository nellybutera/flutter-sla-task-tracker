import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/models/user.dart';
import 'package:sla_task_tracker/routes.dart';
import 'package:sla_task_tracker/screens/sign_in_screen.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

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
  final nameField = find.byKey(const Key('nameField'));
  final addButton = find.text('Add me and continue');

  Future<void> pumpSignIn(
    WidgetTester tester, {
    StorageService? storage,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SignInScreen(storage: storage),
        routes: {
          Routes.dashboard: (_) => const Scaffold(body: Text(dashboardMarker)),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submitName(WidgetTester tester, String name) async {
    await tester.scrollUntilVisible(
      addButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(nameField, name);
    await tester.tap(addButton);
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('lists the saved team members', (tester) async {
    await pumpSignIn(tester);

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Brian'), findsOneWidget);
    expect(find.text('Chloe'), findsOneWidget);
  });

  testWidgets('an empty name shows an error and does not navigate', (
    tester,
  ) async {
    await pumpSignIn(tester);

    await submitName(tester, '   ');

    expect(find.text('Please enter a name.'), findsOneWidget);
    expect(find.text(dashboardMarker), findsNothing);
  });

  testWidgets('a too-short name shows an error', (tester) async {
    await pumpSignIn(tester);

    await submitName(tester, 'A');

    expect(find.text('Name must be at least 2 characters.'), findsOneWidget);
  });

  testWidgets('a name already in the team shows an error', (tester) async {
    await pumpSignIn(tester);

    await submitName(tester, 'alice');

    expect(
      find.text('A team member called "alice" already exists.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a member saves them and opens the dashboard', (
    tester,
  ) async {
    await pumpSignIn(tester);

    await tester.tap(find.text('Brian'));
    await tester.pumpAndSettle();

    expect(find.text(dashboardMarker), findsOneWidget);
    expect((await StorageService().loadCurrentUser())?.name, 'Brian');
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse, reason: 'no way back to Sign In');
  });

  testWidgets('a valid new name is saved and opens the dashboard', (
    tester,
  ) async {
    await pumpSignIn(tester);

    await submitName(tester, '  Belyse ');

    expect(find.text(dashboardMarker), findsOneWidget);
    final users = await StorageService().loadUsers();
    expect(users.map((u) => u.name), contains('Belyse'));
    expect((await StorageService().loadCurrentUser())?.name, 'Belyse');
  });

  testWidgets('a saved user skips sign in on the next launch', (tester) async {
    SharedPreferences.setMockInitialValues({'currentUserId': 'u2'});

    await pumpSignIn(tester);

    expect(find.text(dashboardMarker), findsOneWidget);
    expect(find.text('Team members'), findsNothing);
  });

  testWidgets('a storage error shows a message and Try again recovers', (
    tester,
  ) async {
    await pumpSignIn(tester, storage: _FlakyStorage());

    expect(
      find.text('Could not load the team. Please try again.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
  });
}
