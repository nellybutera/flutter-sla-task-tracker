import '../models/sla_status.dart';
import '../models/task.dart';

/// OWNER: Member B. TODO: replace the stub with the real rule:
/// completed -> overdue (deadline before now) -> atRisk (< 48h left) -> onTrack.
class SlaService {
  static SlaStatus statusFor(Task task, {DateTime? now}) {
    // TODO(Member B): implement. Stub so other screens compile.
    return task.isCompleted ? SlaStatus.completed : SlaStatus.onTrack;
  }
}
