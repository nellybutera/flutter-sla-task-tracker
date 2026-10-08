import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/user.dart';
import '../routes.dart';
import '../services/sla_service.dart';
import '../services/storage_service.dart';
import '../widgets/status_chip.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Task task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final _storage = StorageService();

  late Task _task;

  User? _assignee;
  bool _isLoading = true;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();

    _task = widget.task;
    _loadAssignee();
  }

  Future<void> _loadAssignee() async {
    try {
      final users = await _storage.loadUsers();

      if (!mounted) return;

      setState(() {
        for (final user in users) {
          if (user.id == _task.assigneeId) {
            _assignee = user;
            break;
          }
        }

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError('Could not load task details: $error');
    }
  }

  Future<void> _editTask() async {
    final updatedTask = await Navigator.of(context)
        .pushNamed(Routes.taskForm, arguments: _task);

    if (updatedTask is! Task || !mounted) {
      return;
    }

    setState(() {
      _task = updatedTask;
      _isLoading = true;
    });

    await _loadAssignee();
  }

  Future<void> _markComplete() async {
    if (_task.isCompleted) return;

    setState(() {
      _isWorking = true;
    });

    try {
      final updatedTask = _task.copyWith(isCompleted: true);

      await _storage.saveTask(updatedTask);

      if (!mounted) return;

      setState(() {
        _task = updatedTask;
        _isWorking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task marked as completed.')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isWorking = false;
      });

      _showError('Could not complete task: $error');
    }
  }

  Future<void> _deleteTask() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _isWorking = true;
    });

    try {
      await _storage.deleteTask(_task.id);

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isWorking = false;
      });

      _showError('Could not delete task: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final status = SlaService.statusFor(_task, now: DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            tooltip: 'Edit task',
            onPressed: _isWorking ? null : _editTask,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Delete task',
            onPressed: _isWorking ? null : _deleteTask,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  _task.title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    StatusChip(status: status),
                  ],
                ),

                const Divider(height: 32),

                _InfoRow(
                  label: 'Description',
                  value: _task.description.isEmpty
                      ? 'No description'
                      : _task.description,
                ),

                _InfoRow(
                  label: 'Assignee',
                  value: _assignee?.name ?? 'Unknown',
                ),

                _InfoRow(label: 'Role', value: _assignee?.role ?? 'Unknown'),

                _InfoRow(
                  label: 'Priority',
                  value: _task.priority.name.toUpperCase(),
                ),

                _InfoRow(
                  label: 'Deadline',
                  value:
                      '${_formatDate(_task.deadline)} at '
                      '${_formatTime(_task.deadline)}',
                ),

                _InfoRow(
                  label: 'Completed',
                  value: _task.isCompleted ? 'Yes' : 'No',
                ),

                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: _task.isCompleted || _isWorking
                      ? null
                      : _markComplete,
                  icon: _isWorking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _task.isCompleted ? 'Completed' : 'Mark as Complete',
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _isWorking ? null : _editTask,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Task'),
                ),
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
