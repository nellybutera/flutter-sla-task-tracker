import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/routes.dart';
import 'package:sla_task_tracker/screens/task_list_screen.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

void main() {
  Task makeTask(
    String id,
    String title,
    Priority priority,
    String assignee, {
    bool isCompleted = false,
  }) {
    return Task(
      id: id,
      title: title,
      assigneeId: assignee,
      priority: priority,
      deadline: DateTime(2099, 1, int.parse(id)),
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

  Future<void> pumpTaskList(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const TaskListScreen(),
        routes: {
          Routes.taskDetails: (context) => Scaffold(
            body: Text(
              'Details of ${(ModalRoute.of(context)!.settings.arguments! as Task).title}',
            ),
          ),
          Routes.taskForm: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await StorageService().saveTask(
                  makeTask('9', 'Created in form', Priority.low, 'u1'),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Fake save'),
            ),
          ),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the empty state when there are no tasks', (tester) async {
    await pumpTaskList(tester);

    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('lists saved tasks with the result count', (tester) async {
    await saveTasks([
      makeTask('1', 'Design login', Priority.high, 'u1'),
      makeTask('2', 'Write docs', Priority.low, 'u2'),
    ]);

    await pumpTaskList(tester);

    expect(find.text('Design login'), findsOneWidget);
    expect(find.text('Write docs'), findsOneWidget);
    expect(find.text('Showing 2 of 2 tasks'), findsOneWidget);
  });

  final badge = find.byType(Badge);

  Future<void> choosePriorityInSheet(WidgetTester tester, String label) async {
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Any priority'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Apply in the filter sheet filters by priority', (tester) async {
    await saveTasks([
      makeTask('1', 'Design login', Priority.high, 'u1'),
      makeTask('2', 'Write docs', Priority.low, 'u2'),
    ]);
    await pumpTaskList(tester);

    await choosePriorityInSheet(tester, 'High');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Design login'), findsOneWidget);
    expect(find.text('Write docs'), findsNothing);
    expect(find.text('Showing 1 of 2 tasks'), findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.text('1')),
      findsOneWidget,
      reason: 'badge counts the filters hidden in the sheet',
    );
  });

  testWidgets('swiping the sheet away without Apply changes nothing', (
    tester,
  ) async {
    await saveTasks([
      makeTask('1', 'Design login', Priority.high, 'u1'),
      makeTask('2', 'Write docs', Priority.low, 'u2'),
    ]);
    await pumpTaskList(tester);

    await choosePriorityInSheet(tester, 'High');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Write docs'), findsOneWidget);
    expect(find.text('Showing 2 of 2 tasks'), findsOneWidget);
  });

  testWidgets('Clear filters shows every task again', (tester) async {
    await saveTasks([
      makeTask('1', 'Design login', Priority.high, 'u1'),
      makeTask('2', 'Write docs', Priority.low, 'u2'),
    ]);
    await pumpTaskList(tester);
    await choosePriorityInSheet(tester, 'High');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('Write docs'), findsOneWidget);
    expect(find.text('Clear filters'), findsNothing);
  });

  testWidgets('a status chip shows only tasks with that status', (
    tester,
  ) async {
    await saveTasks([
      makeTask('1', 'Design login', Priority.high, 'u1'),
      makeTask('2', 'Write docs', Priority.low, 'u2', isCompleted: true),
    ]);
    await pumpTaskList(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Completed'));
    await tester.pumpAndSettle();

    expect(find.text('Write docs'), findsOneWidget);
    expect(find.text('Design login'), findsNothing);
  });

  testWidgets('tapping a task opens its details', (tester) async {
    await saveTasks([makeTask('1', 'Design login', Priority.high, 'u1')]);
    await pumpTaskList(tester);

    await tester.tap(find.text('Design login'));
    await tester.pumpAndSettle();

    expect(find.text('Details of Design login'), findsOneWidget);
  });

  testWidgets('the list reloads after returning from the form', (tester) async {
    await pumpTaskList(tester);

    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fake save'));
    await tester.pumpAndSettle();

    expect(find.text('Created in form'), findsOneWidget);
    expect(find.text('No tasks yet'), findsNothing);
  });
}
