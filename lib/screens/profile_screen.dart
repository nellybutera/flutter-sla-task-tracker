import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sla_status.dart';
import '../routes.dart';
import '../services/storage_service.dart';
import '../services/team_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';

class ProfileScreen extends StatefulWidget {
  final StorageService? storage;

  const ProfileScreen({super.key, this.storage});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _maxContentWidth = 560;

  late final StorageService _storage = widget.storage ?? StorageService();

  MemberSummary? _summary;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final user = await _storage.loadCurrentUser();
      final tasks = await _storage.loadTasks();
      if (!mounted) return;
      setState(() {
        _summary = user == null
            ? null
            : TeamService.summarize([user], tasks).single;
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load your profile. Please try again.';
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

  Future<void> _confirmSignOut() async {
    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your tasks stay saved. You can sign back in with your email and password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (isConfirmed != true || !mounted) return;
    await _signOut();
  }

  // clear the saved user first, otherwise Sign In skips straight back here
  Future<void> _signOut() async {
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
        const SnackBar(content: Text('Could not sign out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
    final summary = _summary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              _ProfileHeader(summary: summary),
              if (summary != null) ...[
                const SizedBox(height: 24),
                _TaskCounts(summary: summary),
              ],
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _confirmSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final MemberSummary? summary;

  const _ProfileHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = summary?.user;
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(
            user?.initials ?? '?',
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user?.name ?? 'Not signed in',
          key: const Key('profileName'),
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (user != null) ...[
          Text(
            user.role,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (user.email.isNotEmpty)
            Text(
              user.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ],
    );
  }
}

class _TaskCounts extends StatelessWidget {
  final MemberSummary summary;

  const _TaskCounts({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My tasks', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
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
            key: Key('figure-${label.toLowerCase()}'),
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
