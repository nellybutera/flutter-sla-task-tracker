/// SLA classification shown on every task. The rule lives in SlaService (Member B).
enum SlaStatus { onTrack, atRisk, overdue, completed }

extension SlaStatusLabel on SlaStatus {
  String get label {
    switch (this) {
      case SlaStatus.onTrack:
        return 'On Track';
      case SlaStatus.atRisk:
        return 'At Risk';
      case SlaStatus.overdue:
        return 'Overdue';
      case SlaStatus.completed:
        return 'Completed';
    }
  }
}
