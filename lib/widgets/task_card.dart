import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/sla_service.dart';
import 'status_chip.dart';

/// OWNER: Member C. Basic version so every screen can use it; polish as needed.
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final due = task.deadline.toLocal().toString().substring(0, 16);
    return Card(
      child: ListTile(
        title: Text(task.title),
        subtitle: Text('Due $due  |  ${task.priority.name}'),
        trailing: StatusChip(status: SlaService.statusFor(task)),
        onTap: onTap,
      ),
    );
  }
}
