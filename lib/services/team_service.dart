import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/user.dart';
import 'sla_service.dart';
import 'task_filters.dart';

/// One team member together with the tasks assigned to them.
class MemberSummary {
  final User user;

  /// The member's tasks, earliest deadline first.
  final List<Task> tasks;

  /// How many of [tasks] are Overdue. Completed tasks are never counted.
  final int overdueCount;

  const MemberSummary({
    required this.user,
    required this.tasks,
    required this.overdueCount,
  });

  int get totalCount => tasks.length;

  int get completedCount => tasks.where((task) => task.isCompleted).length;
}

/// Groups tasks by the member they are assigned to.
class TeamService {
  /// Builds one [MemberSummary] per user, in the same order as [users].
  /// Tasks assigned to an unknown user id are ignored. [now] defaults to the
  /// current time and is passed on to the SLA rule, so tests can fix the clock.
  static List<MemberSummary> summarize(
    List<User> users,
    List<Task> tasks, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    return [
      for (final user in users)
        _summaryFor(
          user,
          // Reuses the task list sort: earliest deadline first, ties broken
          // by title so the order never jumps around.
          TaskFilters.apply(
            tasks.where((task) => task.assigneeId == user.id).toList(),
            now: current,
          ),
          current,
        ),
    ];
  }

  static MemberSummary _summaryFor(User user, List<Task> tasks, DateTime now) {
    final overdueCount = tasks
        .where(
          (task) => SlaService.statusFor(task, now: now) == SlaStatus.overdue,
        )
        .length;
    return MemberSummary(user: user, tasks: tasks, overdueCount: overdueCount);
  }
}
