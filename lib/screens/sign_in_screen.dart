import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/user.dart';
import '../routes.dart';
import '../services/storage_service.dart';
import '../services/user_validator.dart';
import '../widgets/error_view.dart';

class SignInScreen extends StatefulWidget {
  final StorageService? storage;

  const SignInScreen({super.key, this.storage});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const double _maxContentWidth = 560;

  late final StorageService _storage = widget.storage ?? StorageService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<User> _users = [];
  String _newUserRole = AppConstants.userRoles.first;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final currentUser = await _storage.loadCurrentUser();
      if (!mounted) return;
      if (currentUser != null) {
        _openDashboard();
        return;
      }
      final users = await _storage.loadUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
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

  Future<void> _signInAs(User user) async {
    setState(() => _isSaving = true);
    try {
      await _storage.setCurrentUser(user.id);
      if (!mounted) return;
      _openDashboard();
    } catch (_) {
      _onSaveFailed('Could not sign in. Please try again.');
    }
  }

  Future<void> _addUserAndSignIn() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final user = User(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      role: _newUserRole,
    );
    setState(() => _isSaving = true);
    try {
      await _storage.saveUser(user);
      await _storage.setCurrentUser(user.id);
      if (!mounted) return;
      _openDashboard();
    } catch (_) {
      _onSaveFailed('Could not save ${user.name}. Please try again.');
    }
  }

  void _onSaveFailed(String message) {
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _openDashboard() {
    unawaited(
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.dashboard,
        (route) => false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: _buildBody(),
          ),
        ),
      ),
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
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 32, 16, 24),
          sliver: SliverToBoxAdapter(child: _Header()),
        ),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: _SectionTitle('Team members')),
        ),
        if (_users.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Text('No team members yet. Add yourself below.'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return _UserTile(
                  user: user,
                  onTap: _isSaving ? null : () => _signInAs(user),
                );
              },
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          sliver: SliverToBoxAdapter(
            child: _AddUserForm(
              formKey: _formKey,
              nameController: _nameController,
              existingNames: _users.map((u) => u.name),
              role: _newUserRole,
              // no setState needed, nothing else on screen uses the role
              onRoleChanged: (role) => _newUserRole = role,
              isSaving: _isSaving,
              onSubmit: _addUserAndSignIn,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.task_alt, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          'SLA Task Tracker',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your profile to continue',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _UserTile extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;
  const _UserTile({required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(user.initials)),
        title: Text(user.name),
        subtitle: Text(user.role),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _AddUserForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final Iterable<String> existingNames;
  final String role;
  final ValueChanged<String> onRoleChanged;
  final bool isSaving;
  final VoidCallback onSubmit;

  const _AddUserForm({
    required this.formKey,
    required this.nameController,
    required this.existingNames,
    required this.role,
    required this.onRoleChanged,
    required this.isSaving,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('New to the team?'),
          TextFormField(
            key: const Key('nameField'),
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Your name',
              helperText:
                  '${AppConstants.userNameMinLength} to '
                  '${AppConstants.userNameMaxLength} characters',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
            validator: (value) =>
                UserValidator.name(value, existingNames: existingNames),
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: role,
            decoration: const InputDecoration(
              labelText: 'Role',
              prefixIcon: Icon(Icons.work_outline),
            ),
            items: [
              for (final option in AppConstants.userRoles)
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: (value) {
              if (value != null) onRoleChanged(value);
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: isSaving ? null : onSubmit,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add me and continue'),
          ),
        ],
      ),
    );
  }
}
