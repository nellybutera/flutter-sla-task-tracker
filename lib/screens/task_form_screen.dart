import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/validators.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _storage = StorageService();

  List<User> _users = [];
  String? _assigneeId;
  Priority _priority = Priority.medium;
  DateTime? _deadline;
  bool _isCompleted = false;

  bool _isLoadingUsers = true;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _assigneeId = task.assigneeId;
      _priority = task.priority;
      _deadline = task.deadline;
      _isCompleted = task.isCompleted;
    }

    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _storage.loadUsers();

      if (!mounted) return;

      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingUsers = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load team members: $error')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: _isEditing ? DateTime(2000) : now,
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) return;

    final initialTime = _deadline != null
        ? TimeOfDay.fromDateTime(_deadline!)
        : TimeOfDay.fromDateTime(now);

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      _deadline = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });

    // Re-run validation after choosing a new date/time.
    _formKey.currentState?.validate();
  }

  Future<void> _saveTask() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _deadline == null || _assigneeId == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();

      final task = Task(
        id: widget.task?.id ?? 'task-${DateTime.now().microsecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assigneeId: _assigneeId!,
        priority: _priority,
        deadline: _deadline!,
        isCompleted: _isCompleted,
        createdAt: widget.task?.createdAt ?? now,
      );

      await _storage.saveTask(task);

      if (!mounted) return;

      Navigator.of(context).pop(task);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save task: $error')));
    }
  }

  String _formatDeadline(DateTime? deadline) {
    if (deadline == null) {
      return 'No deadline selected';
    }

    final date =
        '${deadline.day.toString().padLeft(2, '0')}/'
        '${deadline.month.toString().padLeft(2, '0')}/'
        '${deadline.year}';

    final hour = deadline.hour % 12 == 0 ? 12 : deadline.hour % 12;
    final minute = deadline.minute.toString().padLeft(2, '0');
    final period = deadline.hour >= 12 ? 'PM' : 'AM';

    return '$date at $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'Create Task')),
      body: _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task title',
                      hintText: 'Enter task title',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: Validators.title,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter task description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    maxLength: 300,
                    validator: Validators.description,
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _assigneeId,
                    decoration: const InputDecoration(
                      labelText: 'Assignee',
                      border: OutlineInputBorder(),
                    ),
                    items: _users
                        .map(
                          (user) => DropdownMenuItem<String>(
                            value: user.id,
                            child: Text('${user.name} - ${user.role}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _assigneeId = value;
                      });
                    },
                    validator: Validators.assignee,
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<Priority>(
                    initialValue: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: Priority.values
                        .map(
                          (priority) => DropdownMenuItem<Priority>(
                            value: priority,
                            child: Text(priority.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _priority = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  FormField<DateTime>(
                    initialValue: _deadline,
                    validator: (_) {
                      return Validators.deadline(
                        _deadline,
                        isNewTask: !_isEditing,
                      );
                    },
                    builder: (field) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _selectDeadline,
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              _deadline == null
                                  ? 'Choose deadline'
                                  : _formatDeadline(_deadline),
                            ),
                          ),

                          if (field.hasError)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 8),
                              child: Text(
                                field.errorText!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  if (_isEditing) ...[
                    const SizedBox(height: 16),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Completed'),
                      subtitle: const Text('Mark this task as completed.'),
                      value: _isCompleted,
                      onChanged: (value) {
                        setState(() {
                          _isCompleted = value;
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveTask,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isEditing ? 'Save Changes' : 'Create Task'),
                  ),
                ],
              ),
            ),
    );
  }
}
