import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/models/user.dart';
import 'package:sla_task_tracker/services/team_service.dart';

void main() {
  final now = DateTime(2026, 10, 10, 9);
  const alice = User(id: 'u1', name: 'Alice', role: 'Project Lead');
  const brian = User(id: 'u2', name: 'Brian');

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
      deadline: now.add(fromNow),
      isCompleted: isCompleted,
      createdAt: DateTime(2026, 10, 1),
    );
  }

  group('TeamService.summarize', () {
    test('gives one summary per user, in the same order', () {
      final result = TeamService.summarize(
        const [brian, alice],
        const [],
        now: now,
      );

      expect(result.map((summary) => summary.user.id), ['u2', 'u1']);
    });

    test('a member with no tasks has zero counts', () {
      final result = TeamService.summarize(const [alice], const [], now: now);

      expect(result.single.totalCount, 0);
      expect(result.single.completedCount, 0);
      expect(result.single.overdueCount, 0);
    });

    test('counts each member\'s own tasks', () {
      final tasks = [
        makeTask('1', 'u1', const Duration(days: 3)),
        makeTask('2', 'u1', const Duration(days: 4), isCompleted: true),
        makeTask('3', 'u2', const Duration(days: 5)),
      ];

      final result = TeamService.summarize(
        const [alice, brian],
        tasks,
        now: now,
      );

      expect(result[0].totalCount, 2);
      expect(result[0].completedCount, 1);
      expect(result[1].totalCount, 1);
      expect(result[1].completedCount, 0);
    });

    test('counts overdue tasks only when they are not completed', () {
      final tasks = [
        makeTask('1', 'u1', const Duration(days: -1)),
        makeTask('2', 'u1', const Duration(days: -2)),
        makeTask('3', 'u1', const Duration(days: -3), isCompleted: true),
        makeTask('4', 'u1', const Duration(days: 2)),
      ];

      final result = TeamService.summarize(const [alice], tasks, now: now);

      expect(result.single.overdueCount, 2);
    });

    test('sorts a member\'s tasks by deadline, earliest first', () {
      final tasks = [
        makeTask('late', 'u1', const Duration(days: 9)),
        makeTask('early', 'u1', const Duration(days: 1)),
        makeTask('mid', 'u1', const Duration(days: 4)),
      ];

      final result = TeamService.summarize(const [alice], tasks, now: now);

      expect(result.single.tasks.map((task) => task.id), [
        'early',
        'mid',
        'late',
      ]);
    });

    test('tasks with the same deadline are ordered by title', () {
      final tasks = [
        makeTask('b', 'u1', const Duration(days: 2)).copyWith(title: 'Banana'),
        makeTask('a', 'u1', const Duration(days: 2)).copyWith(title: 'apple'),
        makeTask('c', 'u1', const Duration(days: 2)).copyWith(title: 'Cherry'),
      ];

      final result = TeamService.summarize(const [alice], tasks, now: now);

      expect(result.single.tasks.map((task) => task.title), [
        'apple',
        'Banana',
        'Cherry',
      ]);
    });

    test('ignores tasks assigned to an unknown user', () {
      final tasks = [makeTask('1', 'ghost', const Duration(days: 1))];

      final result = TeamService.summarize(const [alice], tasks, now: now);

      expect(result.single.totalCount, 0);
    });

    test('does not change the list of tasks it is given', () {
      final tasks = [
        makeTask('b', 'u1', const Duration(days: 5)),
        makeTask('a', 'u1', const Duration(days: 1)),
      ];

      TeamService.summarize(const [alice], tasks, now: now);

      expect(tasks.map((task) => task.id), ['b', 'a']);
    });
  });
}
