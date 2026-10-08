import 'package:flutter/material.dart';

import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/sla_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_text.dart';
import 'status_chip.dart';

/// OWNER: Member C.
class TaskCard extends StatelessWidget {
  final Task task;

  final User? assignee;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.assignee, this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = SlaService.statusFor(task, now: now);
    final assignee = this.assignee;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: AppTheme.colorFor(status), width: 5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(status: status),
                  ],
                ),
                const SizedBox(height: 8),
                _DueLine(task: task, status: status, now: now),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _PriorityTag(priority: task.priority),
                    const Spacer(),
                    if (assignee != null) ...[
                      CircleAvatar(
                        radius: 12,
                        child: Text(
                          assignee.initials,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          assignee.name,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DueLine extends StatelessWidget {
  final Task task;
  final SlaStatus status;
  final DateTime now;

  const _DueLine({required this.task, required this.status, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final needsAttention =
        status == SlaStatus.overdue || status == SlaStatus.atRisk;
    return Row(
      children: [
        Icon(Icons.event, size: 16, color: mutedColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: DateText.deadline(task.deadline, now: now),
              children: [
                if (!task.isCompleted)
                  TextSpan(
                    text: '  ·  ${DateText.relative(task.deadline, now: now)}',
                    style: needsAttention
                        ? TextStyle(
                            color: AppTheme.colorFor(status),
                            fontWeight: FontWeight.w600,
                          )
                        : null,
                  ),
              ],
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PriorityTag extends StatelessWidget {
  final Priority priority;
  const _PriorityTag({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.priorityColor(priority);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '${priority.label} priority',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: color),
        ),
      ],
    );
  }
}
