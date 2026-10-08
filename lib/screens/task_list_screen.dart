import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../routes.dart';
import '../services/storage_service.dart';
import '../services/task_filters.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  final StorageService? storage;

  const TaskListScreen({super.key, this.storage});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final StorageService _storage = widget.storage ?? StorageService();

  List<Task> _tasks = [];
  List<User> _users = [];
  TaskFilter _filter = const TaskFilter();
  TaskSort _sort = TaskSort.deadlineSoonest;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final tasks = await _storage.loadTasks();
      final users = await _storage.loadUsers();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _users = users;
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load tasks. Please try again.';
      });
    }
  }

  void _retryLoad() {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    unawaited(_load());
  }

  Future<void> _openDetails(Task task) async {
    await Navigator.pushNamed(context, Routes.taskDetails, arguments: task);
    if (!mounted) return;
    await _load();
  }

  Future<void> _openCreateForm() async {
    await Navigator.pushNamed(context, Routes.taskForm);
    if (!mounted) return;
    await _load();
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<TaskFilter>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(initialFilter: _filter, users: _users),
    );
    if (result == null || !mounted) return;
    _updateFilter(result);
  }

  void _updateFilter(TaskFilter filter) => setState(() => _filter = filter);

  @override
  Widget build(BuildContext context) {
    final hiddenFilterCount = _filter.priorityAndAssigneeCount;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: _openFilterSheet,
            icon: Badge(
              isLabelVisible: hiddenFilterCount > 0,
              label: Text('$hiddenFilterCount'),
              child: const Icon(Icons.tune),
            ),
          ),
          PopupMenuButton<TaskSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort tasks',
            initialValue: _sort,
            onSelected: (sort) => setState(() => _sort = sort),
            itemBuilder: (context) => [
              for (final sort in TaskSort.values)
                CheckedPopupMenuItem(
                  value: sort,
                  checked: sort == _sort,
                  child: Text(sort.label),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final loadError = _loadError;
    if (loadError != null) {
      return ErrorView(message: loadError, onRetry: _retryLoad);
    }
    if (_tasks.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No tasks yet',
        message: 'Tap New task to create the first one.',
      );
    }

    final visibleTasks = TaskFilters.apply(
      _tasks,
      filter: _filter,
      sort: _sort,
    );
    final usersById = {for (final user in _users) user.id: user};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusChipRow(
          selected: _filter.statuses,
          onToggle: (status) => _updateFilter(_filter.toggleStatus(status)),
        ),
        _ResultSummary(
          visibleCount: visibleTasks.length,
          totalCount: _tasks.length,
          canClear: _filter.isActive,
          onClear: () => _updateFilter(const TaskFilter()),
        ),
        Expanded(
          child: visibleTasks.isEmpty
              ? _EmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'No tasks match these filters',
                  message: 'Try another status, priority or assignee.',
                  action: TextButton(
                    onPressed: () => _updateFilter(const TaskFilter()),
                    child: const Text('Clear filters'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: visibleTasks.length,
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      return TaskCard(
                        task: task,
                        assignee: usersById[task.assigneeId],
                        onTap: () => _openDetails(task),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatusChipRow extends StatelessWidget {
  final Set<SlaStatus> selected;
  final ValueChanged<SlaStatus> onToggle;

  const _StatusChipRow({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        spacing: 8,
        children: [
          for (final status in SlaStatus.values)
            _StatusFilterChip(
              status: status,
              isSelected: selected.contains(status),
              onTap: () => onToggle(status),
            ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final SlaStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorFor(status);
    return FilterChip(
      avatar: Icon(AppTheme.iconFor(status), size: 18, color: color),
      label: Text(status.label),
      labelStyle: isSelected
          ? TextStyle(color: color, fontWeight: FontWeight.w600)
          : null,
      showCheckmark: false,
      selected: isSelected,
      selectedColor: AppTheme.backgroundFor(status),
      side: BorderSide(
        color: isSelected
            ? color
            : Theme.of(context).colorScheme.outlineVariant,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  final int visibleCount;
  final int totalCount;
  final bool canClear;
  final VoidCallback onClear;

  const _ResultSummary({
    required this.visibleCount,
    required this.totalCount,
    required this.canClear,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Showing $visibleCount of $totalCount tasks',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (canClear)
              TextButton(
                onPressed: onClear,
                child: const Text('Clear filters'),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final TaskFilter initialFilter;
  final List<User> users;

  const _FilterSheet({required this.initialFilter, required this.users});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  // no setState needed, the dropdowns show their own value
  late Priority? _priority = widget.initialFilter.priority;
  late String? _assigneeId = widget.initialFilter.assigneeId;

  void _apply() {
    Navigator.pop(
      context,
      widget.initialFilter.withPriority(_priority).withAssignee(_assigneeId),
    );
  }

  void _clear() {
    Navigator.pop(
      context,
      widget.initialFilter.withPriority(null).withAssignee(null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filter tasks', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority?>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: [
                const DropdownMenuItem(child: Text('Any priority')),
                for (final priority in Priority.values.reversed)
                  DropdownMenuItem(
                    value: priority,
                    child: Text(priority.label),
                  ),
              ],
              onChanged: (value) => _priority = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _assigneeId,
              decoration: const InputDecoration(
                labelText: 'Assignee',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: [
                const DropdownMenuItem(child: Text('Anyone')),
                for (final user in widget.users)
                  DropdownMenuItem(value: user.id, child: Text(user.name)),
              ],
              onChanged: (value) => _assigneeId = value,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(onPressed: _clear, child: const Text('Clear')),
                const Spacer(),
                FilledButton(onPressed: _apply, child: const Text('Apply')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = this.action;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }
}
