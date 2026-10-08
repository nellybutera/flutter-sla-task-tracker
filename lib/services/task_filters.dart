import '../models/sla_status.dart';
import '../models/task.dart';
import 'sla_service.dart';

enum TaskSort { deadlineSoonest, deadlineLatest, priorityHighest }

extension TaskSortLabel on TaskSort {
  String get label {
    switch (this) {
      case TaskSort.deadlineSoonest:
        return 'Deadline: soonest first';
      case TaskSort.deadlineLatest:
        return 'Deadline: latest first';
      case TaskSort.priorityHighest:
        return 'Priority: highest first';
    }
  }
}

class TaskFilter {
  final Set<SlaStatus> statuses;

  final Priority? priority;

  final String? assigneeId;

  const TaskFilter({this.statuses = const {}, this.priority, this.assigneeId});

  bool get isActive =>
      statuses.isNotEmpty || priority != null || assigneeId != null;

  int get priorityAndAssigneeCount =>
      (priority == null ? 0 : 1) + (assigneeId == null ? 0 : 1);

  TaskFilter toggleStatus(SlaStatus status) {
    final updated = Set.of(statuses);
    if (!updated.remove(status)) {
      updated.add(status);
    }
    return TaskFilter(
      statuses: updated,
      priority: priority,
      assigneeId: assigneeId,
    );
  }

  TaskFilter withPriority(Priority? priority) => TaskFilter(
    statuses: statuses,
    priority: priority,
    assigneeId: assigneeId,
  );

  TaskFilter withAssignee(String? assigneeId) => TaskFilter(
    statuses: statuses,
    priority: priority,
    assigneeId: assigneeId,
  );
}

class TaskFilters {
  static List<Task> apply(
    List<Task> tasks, {
    TaskFilter filter = const TaskFilter(),
    TaskSort sort = TaskSort.deadlineSoonest,
    DateTime? now,
  }) {
    final result = tasks
        .where((task) => matches(task, filter, now: now))
        .toList();
    result.sort(_comparatorFor(sort));
    return result;
  }

  /// Different filters are AND (status + priority + assignee). Statuses
  /// are OR between themselves, e.g. Overdue + At Risk shows both.
  static bool matches(Task task, TaskFilter filter, {DateTime? now}) {
    if (filter.priority != null && task.priority != filter.priority) {
      return false;
    }
    if (filter.assigneeId != null && task.assigneeId != filter.assigneeId) {
      return false;
    }
    if (filter.statuses.isNotEmpty) {
      final status = SlaService.statusFor(task, now: now);
      if (!filter.statuses.contains(status)) {
        return false;
      }
    }
    return true;
  }

  static Comparator<Task> _comparatorFor(TaskSort sort) {
    switch (sort) {
      case TaskSort.deadlineSoonest:
        return (a, b) => _thenByTitle(a.deadline.compareTo(b.deadline), a, b);
      case TaskSort.deadlineLatest:
        return (a, b) => _thenByTitle(b.deadline.compareTo(a.deadline), a, b);
      case TaskSort.priorityHighest:
        return (a, b) {
          final byPriority = b.priority.index.compareTo(a.priority.index);
          if (byPriority != 0) {
            return byPriority;
          }
          return _thenByTitle(a.deadline.compareTo(b.deadline), a, b);
        };
    }
  }

  /// Tie-breaker using the title. List.sort isn't stable, so without this
  /// tasks with the same deadline could swap places.
  static int _thenByTitle(int result, Task a, Task b) {
    if (result != 0) {
      return result;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}
