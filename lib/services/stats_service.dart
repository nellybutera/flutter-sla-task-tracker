import '../models/sla_status.dart';
import '../models/task.dart';

class ProjectStats {
  final int total;
  final int completedCount;
  final double percentComplete; // 0 to 100
  final Map<SlaStatus, int> countByStatus;
  final List<Task> attentionTasks; // overdue first, then at risk

  const ProjectStats({
    required this.total,
    required this.completedCount,
    required this.percentComplete,
    required this.countByStatus,
    required this.attentionTasks,
  });
}

/// OWNER: Member B. TODO: replace the stub with real calculations.
class StatsService {
  static ProjectStats compute(List<Task> tasks, {DateTime? now}) {
    // TODO(Member B): implement. Stub so the dashboard compiles.
    return ProjectStats(
      total: tasks.length,
      completedCount: tasks.where((t) => t.isCompleted).length,
      percentComplete: 0,
      countByStatus: {for (final s in SlaStatus.values) s: 0},
      attentionTasks: const [],
    );
  }
}
