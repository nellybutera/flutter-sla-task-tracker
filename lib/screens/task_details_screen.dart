import 'package:flutter/material.dart';

import '../models/task.dart';

/// OWNER: Member A. TODO: replace this placeholder with the real screen.
class TaskDetailsScreen extends StatelessWidget {
  final Task task;
  const TaskDetailsScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: Center(child: Text('Task Details (placeholder): ${task.title}')),
    );
  }
}
