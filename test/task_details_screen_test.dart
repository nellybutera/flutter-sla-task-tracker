import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/routes.dart';
import 'package:sla_task_tracker/screens/task_details_screen.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

void main() {
  // Seed users: u1 Alice (Project Lead), u2 Brian, u3 Chloe.
  Task makeTask({
    Duration fromNow = const Duration(days: 5),
    bool isCompleted = false,
  }) {
    return Task(
      id: 't1',
      title: 'Write report',
      description: 'First draft',
      assigneeId: 'u1',
      priority: Priority.high,
      deadline: DateTime.now().add(fromNow),
      isCompleted: isCompleted,
      createdAt: DateTime(2026, 9, 1),
    );
  }

  /// Opens the details on top of a home page, so we can tell when it closes.
  Future<void> openDetails(WidgetTester tester, Task task) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await StorageService().saveTask(task);
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          Routes.taskForm: (context) => Scaffold(
            body: Text(
              'Form for ${(ModalRoute.of(context)!.settings.arguments! as Task).title}',
            ),
          ),
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => TaskDetailsScreen(task: task),
                ),
              ),
              child: const Text('open details'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open details'));
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the task information and its assignee', (tester) async {
    await openDetails(tester, makeTask());

    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('First draft'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Project Lead'), findsOneWidget);
  });

  testWidgets('shows On Track for a task due in five days', (tester) async {
    await openDetails(tester, makeTask());

    expect(find.text('On Track'), findsOneWidget);
  });

  testWidgets('shows At Risk for a task due in one hour', (tester) async {
    await openDetails(tester, makeTask(fromNow: const Duration(hours: 1)));

    expect(find.text('At Risk'), findsOneWidget);
  });

  testWidgets('shows Overdue for an unfinished task past its deadline', (
    tester,
  ) async {
    await openDetails(tester, makeTask(fromNow: const Duration(days: -1)));

    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('shows Completed for a finished task', (tester) async {
    await openDetails(
      tester,
      makeTask(fromNow: const Duration(days: -1), isCompleted: true),
    );

    expect(find.text('Completed'), findsWidgets);
    expect(find.text('Overdue'), findsNothing);
  });

  testWidgets('Mark as Complete saves the task as completed', (tester) async {
    await openDetails(tester, makeTask());

    await tester.tap(find.text('Mark as Complete'));
    await tester.pumpAndSettle();

    final tasks = await StorageService().loadTasks();
    expect(tasks.single.isCompleted, isTrue);
    expect(find.text('Mark as Complete'), findsNothing);
    expect(find.text('Completed'), findsWidgets);
  });

  testWidgets('the complete button is disabled for a finished task', (
    tester,
  ) async {
    await openDetails(tester, makeTask(isCompleted: true));

    expect(find.text('Mark as Complete'), findsNothing);
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Completed').last,
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Edit Task opens the form with this task', (tester) async {
    await openDetails(tester, makeTask());

    await tester.tap(find.text('Edit Task'));
    await tester.pumpAndSettle();

    expect(find.text('Form for Write report'), findsOneWidget);
  });

  group('deleting', () {
    testWidgets('asks for confirmation first', (tester) async {
      await openDetails(tester, makeTask());

      await tester.tap(find.byTooltip('Delete task'));
      await tester.pumpAndSettle();

      expect(find.text('Delete task?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
    });

    testWidgets('Cancel keeps the task', (tester) async {
      await openDetails(tester, makeTask());
      await tester.tap(find.byTooltip('Delete task'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await StorageService().loadTasks(), hasLength(1));
      expect(find.byType(TaskDetailsScreen), findsOneWidget);
    });

    testWidgets('Delete removes the task and closes the screen', (
      tester,
    ) async {
      await openDetails(tester, makeTask());
      await tester.tap(find.byTooltip('Delete task'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(await StorageService().loadTasks(), isEmpty);
      expect(find.byType(TaskDetailsScreen), findsNothing);
    });
  });
}
