import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../routes.dart';
import '../services/stats_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';
import '../widgets/task_card.dart';

/// Overview of the project: overall progress, how many tasks are in each SLA
/// status, and the tasks that need attention.
class DashboardScreen extends StatefulWidget {
  /// Storage to read from. Tests pass a fake one; the app uses the default.
  final StorageService? storage;

  const DashboardScreen({super.key, this.storage});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _maxContentWidth = 720;

  late final StorageService _storage = widget.storage ?? StorageService();

  ProjectStats? _stats;
  List<User> _users = [];
  User? _currentUser;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Reads everything the dashboard needs, works out the stats and rebuilds.
  Future<void> _load() async {
    try {
      final tasks = await _storage.loadTasks();
      final users = await _storage.loadUsers();
      final currentUser = await _storage.loadCurrentUser();
      if (!mounted) return;
      setState(() {
        _stats = StatsService.compute(tasks);
        _users = users;
        _currentUser = currentUser;
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load the dashboard. Please try again.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Dashboard')),
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
    final stats = _stats;
    if (stats == null) {
      return const SizedBox.shrink();
    }

    final usersById = {for (final user in _users) user.id: user};
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _Greeting(name: _currentUser?.name),
              const SizedBox(height: 16),
              if (stats.total == 0)
                const _NoTasksMessage()
              else ...[
                _ProgressCard(stats: stats),
                const SizedBox(height: 12),
                _StatusCounts(countByStatus: stats.countByStatus),
                const SizedBox(height: 24),
                _AttentionSection(
                  tasks: stats.attentionTasks,
                  usersById: usersById,
                  onOpen: _openDetails,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String? name;
  const _Greeting({this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = this.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name == null ? 'Hello' : 'Hello, $name',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Here is where the project stands.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NoTasksMessage extends StatelessWidget {
  const _NoTasksMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text('No tasks yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Create tasks from the Tasks tab and the numbers appear here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ProjectStats stats;
  const _ProgressCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = stats.percentComplete;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${percent.round()}%',
                  key: const Key('progressPercent'),
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(width: 8),
                Text('complete', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                key: const Key('progressBar'),
                value: percent / 100,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.completedCount} of ${stats.total} tasks completed',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCounts extends StatelessWidget {
  final Map<SlaStatus, int> countByStatus;
  const _StatusCounts({required this.countByStatus});

  Widget _card(SlaStatus status) {
    return Expanded(
      child: _StatusCountCard(status: status, count: countByStatus[status]!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          spacing: 12,
          children: [_card(SlaStatus.overdue), _card(SlaStatus.atRisk)],
        ),
        const SizedBox(height: 12),
        Row(
          spacing: 12,
          children: [_card(SlaStatus.onTrack), _card(SlaStatus.completed)],
        ),
      ],
    );
  }
}

class _StatusCountCard extends StatelessWidget {
  final SlaStatus status;
  final int count;

  const _StatusCountCard({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.colorFor(status);
    return Semantics(
      label: '${status.label}: $count ${count == 1 ? 'task' : 'tasks'}',
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        color: AppTheme.backgroundFor(status),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppTheme.iconFor(status), color: color),
              const SizedBox(height: 8),
              Text(
                '$count',
                key: Key('count-${status.name}'),
                style: theme.textTheme.headlineMedium?.copyWith(color: color),
              ),
              Text(
                status.label,
                style: theme.textTheme.labelLarge?.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionSection extends StatelessWidget {
  final List<Task> tasks;
  final Map<String, User> usersById;
  final ValueChanged<Task> onOpen;

  const _AttentionSection({
    required this.tasks,
    required this.usersById,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Needs attention', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.colorFor(SlaStatus.onTrack),
                ),
                const Expanded(
                  child: Text('Nothing is overdue or at risk. Nice work.'),
                ),
              ],
            ),
          )
        else
          for (final task in tasks)
            TaskCard(
              task: task,
              assignee: usersById[task.assigneeId],
              onTap: () => onOpen(task),
            ),
      ],
    );
  }
}
