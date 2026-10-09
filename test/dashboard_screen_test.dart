import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/routes.dart';
import 'package:sla_task_tracker/screens/dashboard_screen.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

/// Storage that always fails, to test the error state.
class _FailingStorage extends StorageService {
  @override
  Future<List<Task>> loadTasks() => throw Exception('disk error');
}

void main() {
  // Deadlines are relative to the real clock, so the statuses stay correct
  // whenever the tests run.
  Task makeTask(
    String id,
    String title,
    Duration fromNow, {
    bool isCompleted = false,
    String assignee = 'u1',
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

  Future<void> pumpDashboard(
    WidgetTester tester, {
    StorageService? storage,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(storage: storage),
        routes: {
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

  String countOf(WidgetTester tester, String status) {
    return tester.widget<Text>(find.byKey(Key('count-$status'))).data!;
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final mixedTasks = [
    makeTask('1', 'Write report', const Duration(days: 5)),
    makeTask('2', 'Fix login bug', const Duration(hours: 1)),
    makeTask('3', 'Prepare demo', const Duration(days: -1)),
    makeTask('4', 'Set up CI', const Duration(days: -2), isCompleted: true),
  ];

  testWidgets('shows the empty message when there are no tasks', (
    tester,
  ) async {
    await pumpDashboard(tester);

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.byKey(const Key('progressBar')), findsNothing);
  });

  testWidgets('greets the signed-in user by name', (tester) async {
    await StorageService().setCurrentUser('u1');

    await pumpDashboard(tester);

    expect(find.text('Hello, Alice'), findsOneWidget);
  });

  testWidgets('shows the percent of completed tasks', (tester) async {
    await saveTasks(mixedTasks);

    await pumpDashboard(tester);

    expect(find.text('25%'), findsOneWidget);
    expect(find.text('1 of 4 tasks completed'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('progressBar')),
    );
    expect(bar.value, 0.25);
  });

  testWidgets('shows one count per SLA status', (tester) async {
    await saveTasks(mixedTasks);

    await pumpDashboard(tester);

    expect(countOf(tester, 'overdue'), '1');
    expect(countOf(tester, 'atRisk'), '1');
    expect(countOf(tester, 'onTrack'), '1');
    expect(countOf(tester, 'completed'), '1');
  });

  testWidgets('lists overdue tasks before at-risk ones under attention', (
    tester,
  ) async {
    await saveTasks(mixedTasks);

    await pumpDashboard(tester);

    final overdueY = tester.getTopLeft(find.text('Prepare demo')).dy;
    final atRiskY = tester.getTopLeft(find.text('Fix login bug')).dy;
    expect(overdueY, lessThan(atRiskY));
    expect(find.text('Write report'), findsNothing);
    expect(find.text('Set up CI'), findsNothing);
  });

  testWidgets('says nothing needs attention when all tasks are fine', (
    tester,
  ) async {
    await saveTasks([makeTask('1', 'Write report', const Duration(days: 5))]);

    await pumpDashboard(tester);

    expect(find.text('Nothing is overdue or at risk. Nice work.'), findsOne);
  });

  testWidgets('tapping an attention task opens its details', (tester) async {
    await saveTasks(mixedTasks);
    await pumpDashboard(tester);

    await tester.tap(find.text('Prepare demo'));
    await tester.pumpAndSettle();

    expect(find.text('Details of Prepare demo'), findsOneWidget);
  });

  testWidgets('refreshes the numbers after returning from details', (
    tester,
  ) async {
    await saveTasks(mixedTasks);
    await pumpDashboard(tester);
    expect(countOf(tester, 'overdue'), '1');

    await tester.tap(find.text('Prepare demo'));
    await tester.pumpAndSettle();
    await StorageService().saveTask(mixedTasks[2].copyWith(isCompleted: true));
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(countOf(tester, 'overdue'), '0');
    expect(countOf(tester, 'completed'), '2');
  });

  testWidgets('shows an error with a retry button when loading fails', (
    tester,
  ) async {
    await pumpDashboard(tester, storage: _FailingStorage());

    expect(
      find.text('Could not load the dashboard. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });
}
