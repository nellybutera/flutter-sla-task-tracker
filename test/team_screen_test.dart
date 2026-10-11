import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/routes.dart';
import 'package:sla_task_tracker/screens/team_screen.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

/// Storage that always fails, to test the error state.
class _FailingStorage extends StorageService {
  @override
  Future<List<Task>> loadTasks() => throw Exception('disk error');
}

void main() {
  // Deadlines are relative to the real clock, so statuses stay correct
  // whenever the tests run. Seed users: u1 Alice, u2 Brian, u3 Chloe.
  Task makeTask(
    String id,
    String title,
    String assignee,
    Duration fromNow, {
    bool isCompleted = false,
  }) {
    return Task(
      id: id,
      title: title,
      assigneeId: assignee,
      priority: Priority.medium,
      deadline: DateTime.now().add(fromNow),
      isCompleted: isCompleted,
      createdAt: DateTime(2026, 9, 1),
    );
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final storage = StorageService();
    for (final task in tasks) {
      await storage.saveTask(task);
    }
  }

  Future<void> pumpTeam(WidgetTester tester, {StorageService? storage}) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: TeamScreen(storage: storage),
        routes: {
          Routes.signIn: (context) =>
              const Scaffold(body: Text('Sign in page')),
          Routes.taskDetails: (context) => Scaffold(
            body: Text(
              'Details of ${(ModalRoute.of(context)!.settings.arguments! as Task).title}',
            ),
          ),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final tasks = [
    makeTask('1', 'Prepare demo', 'u1', const Duration(days: -1)),
    makeTask('2', 'Write report', 'u1', const Duration(days: 4)),
    makeTask(
      '3',
      'Set up CI',
      'u1',
      const Duration(days: -3),
      isCompleted: true,
    ),
    makeTask('4', 'Fix login bug', 'u2', const Duration(hours: 2)),
  ];

  testWidgets('shows the signed-in user as the profile', (tester) async {
    await StorageService().setCurrentUser('u1');

    await pumpTeam(tester);

    expect(
      tester.widget<Text>(find.byKey(const Key('profileName'))).data,
      'Alice',
    );
    expect(find.text('Project Lead'), findsOneWidget);
  });

  testWidgets('profile shows assigned, completed and overdue counts', (
    tester,
  ) async {
    await StorageService().setCurrentUser('u1');
    await saveTasks(tasks);

    await pumpTeam(tester);

    // Alice: 3 assigned, 1 completed, 1 overdue.
    String figure(String name) =>
        tester.widget<Text>(find.byKey(Key('figure-$name'))).data!;
    expect(figure('assigned'), '3');
    expect(figure('completed'), '1');
    expect(figure('overdue'), '1');
  });

  testWidgets('every member row keeps its expand arrow', (tester) async {
    await StorageService().setCurrentUser('u1');
    await saveTasks(tasks);

    await pumpTeam(tester);

    // Alice has an overdue task, but her row must still show the arrow.
    expect(find.byIcon(Icons.expand_more), findsNWidgets(3));
  });

  testWidgets('lists every member with their task count', (tester) async {
    await StorageService().setCurrentUser('u1');
    await saveTasks(tasks);

    await pumpTeam(tester);

    expect(find.text('Team (3)'), findsOneWidget);
    expect(find.text('Alice (you)'), findsOneWidget);
    expect(find.text('Brian'), findsOneWidget);
    expect(find.text('Chloe'), findsOneWidget);
    expect(find.textContaining('3 tasks'), findsOneWidget);
    expect(find.textContaining('1 task'), findsWidgets);
    expect(find.textContaining('0 tasks'), findsOneWidget);
  });

  testWidgets('shows an overdue badge only for members with overdue tasks', (
    tester,
  ) async {
    await StorageService().setCurrentUser('u1');
    await saveTasks(tasks);

    await pumpTeam(tester);

    expect(find.byKey(const Key('overdue-u1')), findsOneWidget);
    expect(find.byKey(const Key('overdue-u2')), findsNothing);
    expect(find.byKey(const Key('overdue-u3')), findsNothing);
  });

  testWidgets('tapping a member shows their tasks', (tester) async {
    await StorageService().setCurrentUser('u1');
    await saveTasks(tasks);
    await pumpTeam(tester);
    expect(find.text('Fix login bug'), findsNothing);

    await tester.tap(find.text('Brian'));
    await tester.pumpAndSettle();

    expect(find.text('Fix login bug'), findsOneWidget);
  });

  testWidgets('a member with no tasks says so', (tester) async {
    await StorageService().setCurrentUser('u1');
    await pumpTeam(tester);

    await tester.tap(find.text('Chloe'));
    await tester.pumpAndSettle();

    expect(find.text('No tasks assigned.'), findsOneWidget);
  });

  testWidgets('tapping a task opens its details', (tester) async {
    await StorageService().setCurrentUser('u1');
    await saveTasks(tasks);
    await pumpTeam(tester);
    await tester.tap(find.text('Brian'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fix login bug'));
    await tester.pumpAndSettle();

    expect(find.text('Details of Fix login bug'), findsOneWidget);
  });

  testWidgets('switch user signs out and opens the sign in page', (
    tester,
  ) async {
    await StorageService().setCurrentUser('u1');
    await pumpTeam(tester);

    await tester.tap(find.text('Switch user'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in page'), findsOneWidget);
    expect(await StorageService().loadCurrentUser(), isNull);
  });

  testWidgets('shows an error with a retry button when loading fails', (
    tester,
  ) async {
    await pumpTeam(tester, storage: _FailingStorage());

    expect(
      find.text('Could not load the team. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });
}
