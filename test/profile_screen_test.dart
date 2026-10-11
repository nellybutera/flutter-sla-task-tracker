import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/routes.dart';
import 'package:sla_task_tracker/screens/home_shell.dart';
import 'package:sla_task_tracker/screens/profile_screen.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

class _FailingStorage extends StorageService {
  @override
  Future<List<Task>> loadTasks() => throw Exception('disk error');
}

void main() {
  Task makeTask(
    String id,
    String assignee,
    Duration fromNow, {
    bool isCompleted = false,
  }) {
    return Task(
      id: id,
      title: 'Task $id',
      assigneeId: assignee,
      priority: Priority.medium,
      deadline: DateTime.now().add(fromNow),
      isCompleted: isCompleted,
      createdAt: DateTime(2026, 9, 1),
    );
  }

  Future<void> pumpProfile(
    WidgetTester tester, {
    StorageService? storage,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(storage: storage),
        routes: {
          Routes.signIn: (context) =>
              const Scaffold(body: Text('Sign in page')),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  String profileName(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('profileName'))).data!;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the signed-in user', (tester) async {
    await StorageService().setCurrentUser('u1');

    await pumpProfile(tester);

    expect(profileName(tester), 'Alice');
    expect(find.text('Project Lead'), findsOneWidget);
    expect(find.text('alice@demo.com'), findsOneWidget);
  });

  testWidgets('shows assigned, completed and overdue counts', (tester) async {
    await StorageService().setCurrentUser('u1');
    final storage = StorageService();
    await storage.saveTask(makeTask('1', 'u1', const Duration(days: -1)));
    await storage.saveTask(makeTask('2', 'u1', const Duration(days: 4)));
    await storage.saveTask(
      makeTask('3', 'u1', const Duration(days: -3), isCompleted: true),
    );
    await storage.saveTask(makeTask('4', 'u2', const Duration(days: -1)));

    await pumpProfile(tester);

    String figure(String name) =>
        tester.widget<Text>(find.byKey(Key('figure-$name'))).data!;
    expect(figure('assigned'), '3');
    expect(figure('completed'), '1');
    expect(figure('overdue'), '1');
  });

  testWidgets('Cancel in the sign out dialog keeps you signed in', (
    tester,
  ) async {
    await StorageService().setCurrentUser('u1');
    await pumpProfile(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(profileName(tester), 'Alice');
    expect((await StorageService().loadCurrentUser())?.name, 'Alice');
  });

  testWidgets('confirming sign out clears the user and opens Sign In', (
    tester,
  ) async {
    await StorageService().setCurrentUser('u1');
    await pumpProfile(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in page'), findsOneWidget);
    expect(await StorageService().loadCurrentUser(), isNull);
  });

  testWidgets('shows an error with a retry button when loading fails', (
    tester,
  ) async {
    await pumpProfile(tester, storage: _FailingStorage());

    expect(
      find.text('Could not load your profile. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('the bottom bar has a Profile tab that opens this screen', (
    tester,
  ) async {
    await StorageService().setCurrentUser('u1');
    await tester.pumpWidget(
      const MaterialApp(home: HomeShell(), onGenerateRoute: Routes.generate),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(profileName(tester), 'Alice');
  });
}
