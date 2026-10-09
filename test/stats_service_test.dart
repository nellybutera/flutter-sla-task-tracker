import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker/models/sla_status.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/services/stats_service.dart';

void main() {
  final now = DateTime(2026, 10, 10, 9);

  Task makeTask(String id, Duration fromNow, {bool isCompleted = false}) {
    return Task(
      id: id,
      title: 'Task $id',
      assigneeId: 'u1',
      priority: Priority.medium,
      deadline: now.add(fromNow),
      isCompleted: isCompleted,
      createdAt: DateTime(2026, 10, 1),
    );
  }

  group('StatsService.compute', () {
    test('an empty list gives zeros without dividing by zero', () {
      final stats = StatsService.compute(const [], now: now);

      expect(stats.total, 0);
      expect(stats.completedCount, 0);
      expect(stats.percentComplete, 0);
      expect(stats.attentionTasks, isEmpty);
    });

    test('every status key is present even when its count is zero', () {
      final stats = StatsService.compute(const [], now: now);

      expect(stats.countByStatus.keys, SlaStatus.values);
      expect(stats.countByStatus.values.every((count) => count == 0), isTrue);
    });

    test('counts tasks per status', () {
      final tasks = [
        makeTask('1', const Duration(days: 5)),
        makeTask('2', const Duration(days: 9)),
        makeTask('3', const Duration(hours: 5)),
        makeTask('4', const Duration(days: -1)),
        makeTask('5', const Duration(days: -2), isCompleted: true),
      ];

      final stats = StatsService.compute(tasks, now: now);

      expect(stats.total, 5);
      expect(stats.countByStatus[SlaStatus.onTrack], 2);
      expect(stats.countByStatus[SlaStatus.atRisk], 1);
      expect(stats.countByStatus[SlaStatus.overdue], 1);
      expect(stats.countByStatus[SlaStatus.completed], 1);
    });

    test('percent complete is completed tasks divided by all tasks', () {
      final tasks = [
        makeTask('1', const Duration(days: 5), isCompleted: true),
        makeTask('2', const Duration(days: 5)),
        makeTask('3', const Duration(days: 5)),
        makeTask('4', const Duration(days: 5)),
      ];

      final stats = StatsService.compute(tasks, now: now);

      expect(stats.completedCount, 1);
      expect(stats.percentComplete, 25);
    });

    test('percent is 100 when every task is completed', () {
      final tasks = [
        makeTask('1', const Duration(days: -3), isCompleted: true),
        makeTask('2', const Duration(days: 3), isCompleted: true),
      ];

      expect(StatsService.compute(tasks, now: now).percentComplete, 100);
    });

    test('attention list has overdue first, then at risk, by deadline', () {
      final tasks = [
        makeTask('risk-late', const Duration(hours: 40)),
        makeTask('overdue-recent', const Duration(hours: -2)),
        makeTask('fine', const Duration(days: 10)),
        makeTask('risk-soon', const Duration(hours: 3)),
        makeTask('overdue-old', const Duration(days: -4)),
      ];

      final stats = StatsService.compute(tasks, now: now);

      expect(stats.attentionTasks.map((task) => task.id), [
        'overdue-old',
        'overdue-recent',
        'risk-soon',
        'risk-late',
      ]);
    });

    test('completed and on-track tasks are not in the attention list', () {
      final tasks = [
        makeTask('done-late', const Duration(days: -2), isCompleted: true),
        makeTask('fine', const Duration(days: 10)),
      ];

      expect(StatsService.compute(tasks, now: now).attentionTasks, isEmpty);
    });

    test('does not change the order of the list it is given', () {
      final tasks = [
        makeTask('b', const Duration(days: -1)),
        makeTask('a', const Duration(days: -3)),
      ];

      StatsService.compute(tasks, now: now);

      expect(tasks.map((task) => task.id), ['b', 'a']);
    });
  });
}
