import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker/models/sla_status.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/services/task_filters.dart';

void main() {
  final now = DateTime(2026, 10, 1, 9);

  Task makeTask(
    String id,
    String title, {
    required String assigneeId,
    required Priority priority,
    required DateTime deadline,
    bool isCompleted = false,
  }) {
    return Task(
      id: id,
      title: title,
      assigneeId: assigneeId,
      priority: priority,
      deadline: deadline,
      isCompleted: isCompleted,
      createdAt: DateTime(2026, 9, 1),
    );
  }

  final design = makeTask(
    't1',
    'Design login',
    assigneeId: 'u1',
    priority: Priority.high,
    deadline: DateTime(2026, 12, 1),
  );
  final docs = makeTask(
    't2',
    'Write API docs',
    assigneeId: 'u2',
    priority: Priority.low,
    deadline: DateTime(2026, 11, 15),
    isCompleted: true,
  );
  final crash = makeTask(
    't3',
    'Fix crash',
    assigneeId: 'u1',
    priority: Priority.medium,
    deadline: DateTime(2026, 11, 20),
  );
  final sprint = makeTask(
    't4',
    'Plan sprint',
    assigneeId: 'u3',
    priority: Priority.high,
    deadline: DateTime(2026, 11, 10),
    isCompleted: true,
  );
  final tasks = [design, docs, crash, sprint];

  List<String> ids(List<Task> list) => list.map((t) => t.id).toList();

  group('TaskFilters.apply filtering', () {
    test('no filter returns every task', () {
      final result = TaskFilters.apply(tasks, now: now);

      expect(result, hasLength(4));
    });

    test('an empty list stays empty', () {
      expect(TaskFilters.apply(const [], now: now), isEmpty);
    });

    test('does not reorder the original list', () {
      TaskFilters.apply(tasks, sort: TaskSort.deadlineLatest, now: now);

      expect(ids(tasks), ['t1', 't2', 't3', 't4']);
    });

    test('filters by priority', () {
      const filter = TaskFilter(priority: Priority.high);

      final result = TaskFilters.apply(tasks, filter: filter, now: now);

      expect(ids(result), ['t4', 't1']);
    });

    test('filters by assignee', () {
      const filter = TaskFilter(assigneeId: 'u1');

      final result = TaskFilters.apply(tasks, filter: filter, now: now);

      expect(ids(result), ['t3', 't1']);
    });

    test('filters by a single status', () {
      const filter = TaskFilter(statuses: {SlaStatus.completed});

      final result = TaskFilters.apply(tasks, filter: filter, now: now);

      expect(ids(result), ['t4', 't2']);
    });

    test('several statuses combine with OR', () {
      const filter = TaskFilter(
        statuses: {SlaStatus.completed, SlaStatus.onTrack},
      );

      final result = TaskFilters.apply(tasks, filter: filter, now: now);

      expect(result, hasLength(4));
    });

    test('assignee and priority combine with AND', () {
      const filter = TaskFilter(assigneeId: 'u1', priority: Priority.high);

      final result = TaskFilters.apply(tasks, filter: filter, now: now);

      expect(ids(result), ['t1']);
    });

    test('status, priority and assignee all combine', () {
      const filter = TaskFilter(
        statuses: {SlaStatus.completed},
        priority: Priority.high,
        assigneeId: 'u3',
      );

      final result = TaskFilters.apply(tasks, filter: filter, now: now);

      expect(ids(result), ['t4']);
    });

    test('returns an empty list when nothing matches', () {
      const filter = TaskFilter(
        statuses: {SlaStatus.completed},
        assigneeId: 'u1',
      );

      expect(TaskFilters.apply(tasks, filter: filter, now: now), isEmpty);
    });
  });

  group('TaskFilters.apply sorting', () {
    test('soonest deadline first by default', () {
      final result = TaskFilters.apply(tasks, now: now);

      expect(ids(result), ['t4', 't2', 't3', 't1']);
    });

    test('latest deadline first', () {
      final result = TaskFilters.apply(
        tasks,
        sort: TaskSort.deadlineLatest,
        now: now,
      );

      expect(ids(result), ['t1', 't3', 't2', 't4']);
    });

    test('highest priority first, then soonest deadline', () {
      final result = TaskFilters.apply(
        tasks,
        sort: TaskSort.priorityHighest,
        now: now,
      );

      expect(ids(result), ['t4', 't1', 't3', 't2']);
    });

    test('tasks with the same deadline are ordered by title', () {
      final sameDay = DateTime(2026, 11, 1);
      final zebra = makeTask(
        'z',
        'Zebra',
        assigneeId: 'u1',
        priority: Priority.low,
        deadline: sameDay,
      );
      final apple = makeTask(
        'a',
        'apple',
        assigneeId: 'u1',
        priority: Priority.low,
        deadline: sameDay,
      );

      final result = TaskFilters.apply([zebra, apple], now: now);

      expect(ids(result), ['a', 'z']);
    });
  });

  group('TaskFilter', () {
    test('is not active by default', () {
      expect(const TaskFilter().isActive, isFalse);
    });

    test('priorityAndAssigneeCount ignores statuses', () {
      const none = TaskFilter(statuses: {SlaStatus.overdue});
      const one = TaskFilter(priority: Priority.high);
      const both = TaskFilter(priority: Priority.low, assigneeId: 'u1');

      expect(none.priorityAndAssigneeCount, 0);
      expect(one.priorityAndAssigneeCount, 1);
      expect(both.priorityAndAssigneeCount, 2);
    });

    test('toggleStatus adds a status, then removes it', () {
      const empty = TaskFilter();

      final once = empty.toggleStatus(SlaStatus.overdue);
      final twice = once.toggleStatus(SlaStatus.overdue);

      expect(once.statuses, {SlaStatus.overdue});
      expect(once.isActive, isTrue);
      expect(twice.statuses, isEmpty);
      expect(empty.statuses, isEmpty, reason: 'original is unchanged');
    });

    test('withPriority(null) clears only the priority', () {
      const filter = TaskFilter(priority: Priority.low, assigneeId: 'u2');

      final cleared = filter.withPriority(null);

      expect(cleared.priority, isNull);
      expect(cleared.assigneeId, 'u2');
    });

    test('withAssignee(null) clears only the assignee', () {
      const filter = TaskFilter(priority: Priority.low, assigneeId: 'u2');

      final cleared = filter.withAssignee(null);

      expect(cleared.assigneeId, isNull);
      expect(cleared.priority, Priority.low);
    });
  });
}
