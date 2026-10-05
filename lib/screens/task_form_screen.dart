import 'package:flutter/material.dart';

import '../models/task.dart';

/// OWNER: Member C. TODO: replace this placeholder with the real screen.
class TaskFormScreen extends StatelessWidget {
  final Task? task; // null means create a new task
  const TaskFormScreen({super.key, this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(task == null ? 'Create Task' : 'Edit Task')),
      body: const Center(child: Text('Create / Edit Task (placeholder)')),
    );
  }
}
