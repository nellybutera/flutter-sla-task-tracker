import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/screens/task_form_screen.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

void main() {
  // Seed users: u1 Alice, u2 Brian, u3 Chloe.
  final existingTask = Task(
    id: 't1',
    title: 'Write report',
    description: 'First draft',
    assigneeId: 'u1',
    priority: Priority.high,
    deadline: DateTime.now().add(const Duration(days: 5)),
    createdAt: DateTime(2026, 9, 1),
  );

  /// Opens the form on top of a home page, so we can tell when it closes.
  Future<void> openForm(WidgetTester tester, {Task? task}) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => TaskFormScreen(task: task),
                ),
              ),
              child: const Text('open form'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open form'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  final createButton = find.descendant(
    of: find.bySubtype<FilledButton>(),
    matching: find.text('Create Task'),
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('creating a task', () {
    testWidgets('shows the create title and no completed switch', (
      tester,
    ) async {
      await openForm(tester);

      expect(find.text('Create Task'), findsNWidgets(2)); // title + button
      expect(find.text('Completed'), findsNothing);
    });

    testWidgets('an empty form shows an error under each required field', (
      tester,
    ) async {
      await openForm(tester);

      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Title is required.'), findsOneWidget);
      expect(find.text('Please select an assignee.'), findsOneWidget);
      expect(find.text('Please select a deadline.'), findsOneWidget);
    });

    testWidgets('a title that is too short shows an error', (tester) async {
      await openForm(tester);

      await tester.enterText(field('Task title'), 'ab');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Title must be at least'), findsOneWidget);
    });

    testWidgets('an invalid form is not saved and stays open', (tester) async {
      await openForm(tester);

      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(await StorageService().loadTasks(), isEmpty);
      expect(find.byType(TaskFormScreen), findsOneWidget);
    });
  });

  group('editing a task', () {
    testWidgets('shows the edit title and the existing values', (tester) async {
      await openForm(tester, task: existingTask);

      expect(find.text('Edit Task'), findsOneWidget);
      expect(find.text('Write report'), findsOneWidget);
      expect(find.text('First draft'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('saving a changed title updates the stored task', (
      tester,
    ) async {
      await StorageService().saveTask(existingTask);
      await openForm(tester, task: existingTask);

      await tester.enterText(field('Task title'), 'Final report');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      final tasks = await StorageService().loadTasks();
      expect(tasks, hasLength(1));
      expect(tasks.single.id, 't1');
      expect(tasks.single.title, 'Final report');
      expect(tasks.single.assigneeId, 'u1');
      expect(find.byType(TaskFormScreen), findsNothing);
    });

    testWidgets('the completed switch is saved', (tester) async {
      await StorageService().saveTask(existingTask);
      await openForm(tester, task: existingTask);

      await tester.tap(find.byType(SwitchListTile));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      final tasks = await StorageService().loadTasks();
      expect(tasks.single.isCompleted, isTrue);
    });

    testWidgets('clearing the title shows an error and does not save', (
      tester,
    ) async {
      await StorageService().saveTask(existingTask);
      await openForm(tester, task: existingTask);

      await tester.enterText(field('Task title'), '');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required.'), findsOneWidget);
      final tasks = await StorageService().loadTasks();
      expect(tasks.single.title, 'Write report');
      expect(find.byType(TaskFormScreen), findsOneWidget);
    });

    testWidgets('an old deadline can stay when editing', (tester) async {
      final overdueTask = existingTask.copyWith(
        deadline: DateTime.now().subtract(const Duration(days: 2)),
      );
      await StorageService().saveTask(overdueTask);
      await openForm(tester, task: overdueTask);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Deadline cannot be in the past.'), findsNothing);
      expect(find.byType(TaskFormScreen), findsNothing);
    });
  });
}
