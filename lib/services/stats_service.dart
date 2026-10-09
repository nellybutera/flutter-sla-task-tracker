import '../models/sla_status.dart';
import '../models/task.dart';
import 'sla_service.dart';

/// Numbers shown on the dashboard.
class ProjectStats {
  final int total;
  final int completedCount;

  /// Share of finished tasks, from 0 to 100. It is 0 when there are no tasks.
  final double percentComplete;

  /// How many tasks have each status. Every [SlaStatus] is always present.
  final Map<SlaStatus, int> countByStatus;

  /// Tasks that need action: Overdue first, then At Risk. Inside each group
  /// the earliest deadline comes first.
  final List<Task> attentionTasks;

  const ProjectStats({
    required this.total,
    required this.completedCount,
    required this.percentComplete,
    required this.countByStatus,
    required this.attentionTasks,
  });
}

/// Calculates the dashboard numbers from a list of tasks.
class StatsService {
  /// Computes [ProjectStats] for [tasks] at time [now] (defaults to the
  /// current time). Each task's status is worked out once, with the same
  /// [now], so the counts and the attention list always agree.
  static ProjectStats compute(List<Task> tasks, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final countByStatus = {for (final status in SlaStatus.values) status: 0};
    final overdue = <Task>[];
    final atRisk = <Task>[];

    for (final task in tasks) {
      final status = SlaService.statusFor(task, now: current);
      countByStatus[status] = countByStatus[status]! + 1;
      if (status == SlaStatus.overdue) {
        overdue.add(task);
      } else if (status == SlaStatus.atRisk) {
        atRisk.add(task);
      }
    }

    int byDeadline(Task a, Task b) => a.deadline.compareTo(b.deadline);
    overdue.sort(byDeadline);
    atRisk.sort(byDeadline);

    final completedCount = countByStatus[SlaStatus.completed]!;
    return ProjectStats(
      total: tasks.length,
      completedCount: completedCount,
      percentComplete: tasks.isEmpty ? 0 : completedCount / tasks.length * 100,
      countByStatus: countByStatus,
      attentionTasks: [...overdue, ...atRisk],
    );
  }
}
