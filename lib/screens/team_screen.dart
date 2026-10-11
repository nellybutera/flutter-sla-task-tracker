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

/// Shows the signed-in user's profile, lets them switch user, and lists every
/// team member with their task counts. Tap a member to see their tasks.
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

  /// Forgets the signed-in user and goes back to the Sign In screen.
  Future<void> _switchUser() async {
    try {
      await _storage.clearCurrentUser();
      if (!mounted) return;
      unawaited(
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.signIn,
          (route) => false,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not switch user. Please try again.'),
        ),
      );
    }
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
    MemberSummary? mine;
    for (final member in _members) {
      if (member.user.id == currentId) mine = member;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _ProfileCard(summary: mine, onSwitchUser: _switchUser),
              const SizedBox(height: 24),
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

class _ProfileCard extends StatelessWidget {
  final MemberSummary? summary;
  final VoidCallback onSwitchUser;

  const _ProfileCard({required this.summary, required this.onSwitchUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = this.summary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    summary?.user.initials ?? '?',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary?.user.name ?? 'Not signed in',
                        key: const Key('profileName'),
                        style: theme.textTheme.titleLarge,
                      ),
                      if (summary != null)
                        Text(
                          summary.user.role,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (summary != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _Figure(label: 'Assigned', value: summary.totalCount),
                  _Figure(label: 'Completed', value: summary.completedCount),
                  _Figure(
                    label: 'Overdue',
                    value: summary.overdueCount,
                    color: summary.overdueCount > 0
                        ? AppTheme.colorFor(SlaStatus.overdue)
                        : null,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSwitchUser,
                icon: const Icon(Icons.switch_account_outlined),
                label: const Text('Switch user'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;

  const _Figure({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(color: color),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
        subtitle: Text(
          '${user.role}  ·  $count ${count == 1 ? 'task' : 'tasks'}',
        ),
        trailing: summary.overdueCount > 0
            ? Chip(
                key: Key('overdue-${user.id}'),
                label: Text('${summary.overdueCount} overdue'),
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.colorFor(SlaStatus.overdue),
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: AppTheme.backgroundFor(SlaStatus.overdue),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              )
            : null,
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
