import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../routes.dart';
import '../services/storage_service.dart';
import '../services/team_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';
import '../widgets/task_card.dart';

/// Lists every team member with their task counts. Tap a member to see their
/// tasks.
class TeamScreen extends StatefulWidget {
  /// Storage to read from. Tests pass a fake one; the app uses the default.
  final StorageService? storage;

  const TeamScreen({super.key, this.storage});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  static const double _maxContentWidth = 720;

  late final StorageService _storage = widget.storage ?? StorageService();

  List<MemberSummary> _members = [];
  User? _currentUser;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Reads users and tasks, groups the tasks by member and rebuilds.
  Future<void> _load() async {
    try {
      final users = await _storage.loadUsers();
      final tasks = await _storage.loadTasks();
      final currentUser = await _storage.loadCurrentUser();
      if (!mounted) return;
      setState(() {
        _members = TeamService.summarize(users, tasks);
        _currentUser = currentUser;
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load the team. Please try again.';
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
      appBar: AppBar(title: const Text('Team Members')),
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

    final currentId = _currentUser?.id;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                'Team (${_members.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              for (final member in _members)
                _MemberTile(
                  summary: member,
                  isCurrentUser: member.user.id == currentId,
                  onOpenTask: _openDetails,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final MemberSummary summary;
  final bool isCurrentUser;
  final ValueChanged<Task> onOpenTask;

  const _MemberTile({
    required this.summary,
    required this.isCurrentUser,
    required this.onOpenTask,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = summary.user;
    final count = summary.totalCount;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey('member-${user.id}'),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(child: Text(user.initials)),
        title: Text(isCurrentUser ? '${user.name} (you)' : user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${user.role}  ·  $count ${count == 1 ? 'task' : 'tasks'}'),
            if (summary.overdueCount > 0)
              Text(
                '${summary.overdueCount} overdue',
                key: Key('overdue-${user.id}'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.colorFor(SlaStatus.overdue),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        children: [
          if (summary.tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No tasks assigned.'),
            )
          else
            for (final task in summary.tasks)
              TaskCard(
                task: task,
                assignee: user,
                onTap: () => onOpenTask(task),
              ),
        ],
      ),
    );
  }
}
