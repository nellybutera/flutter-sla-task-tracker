import '../constants/app_constants.dart';
import '../models/sla_status.dart';
import '../models/task.dart';

/// Decides the SLA status of a task from its deadline and completion.
class SlaService {
  /// Returns the status of [task] at time [now] (defaults to the current time).
  ///
  /// The checks run in this order, and the first one that matches wins:
  /// 1. Completed: a finished task is never late, even past its deadline.
  /// 2. Overdue: not finished and the deadline is already in the past.
  /// 3. At Risk: not overdue, but less than [AppConstants.atRiskWindow] left.
  /// 4. On Track: everything else.
  ///
  /// Boundaries: a deadline equal to [now] is At Risk (it has not passed yet),
  /// and exactly [AppConstants.atRiskWindow] left is still On Track.
  ///
  /// [now] is a parameter so tests can fix the clock.
  static SlaStatus statusFor(Task task, {DateTime? now}) {
    if (task.isCompleted) {
      return SlaStatus.completed;
    }
    final current = now ?? DateTime.now();
    if (task.deadline.isBefore(current)) {
      return SlaStatus.overdue;
    }
    final timeLeft = task.deadline.difference(current);
    if (timeLeft < AppConstants.atRiskWindow) {
      return SlaStatus.atRisk;
    }
    return SlaStatus.onTrack;
  }
}
