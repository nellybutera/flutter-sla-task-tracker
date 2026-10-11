import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/user.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/user_validator.dart';
import '../widgets/error_view.dart';
import '../widgets/password_field.dart';

class SignUpScreen extends StatefulWidget {
  final StorageService? storage;

  const SignUpScreen({super.key, this.storage});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const double _maxContentWidth = 480;

  late final StorageService _storage = widget.storage ?? StorageService();
  late final AuthService _auth = AuthService(storage: _storage);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // loaded so the form can say "already taken" before saving
  List<User> _users = [];
  String _role = AppConstants.userRoles.first;
  bool _isLoading = true;
  bool _isCreating = false;
  String? _loadError;
  String? _signUpError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadUsers());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
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

  void _retry() {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    unawaited(_loadUsers());
  }

  Future<void> _createAccount() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isCreating = true;
      _signUpError = null;
    });
    try {
      await _auth.signUp(
        name: _nameController.text,
        email: _emailController.text,
        role: _role,
        password: _passwordController.text,
      );
      if (!mounted) return;
      unawaited(
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.dashboard,
          (route) => false,
        ),
      );
    } on AuthException catch (error) {
      _showSignUpError(error.message);
    } catch (_) {
      _showSignUpError('Could not create your account. Please try again.');
    }
  }

  void _showSignUpError(String message) {
    if (!mounted) return;
    setState(() {
      _isCreating = false;
      _signUpError = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
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
      return ErrorView(message: loadError, onRetry: _retry);
    }
    final signUpError = _signUpError;
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('nameField'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                helperText:
                    '${AppConstants.userNameMinLength} to '
                    '${AppConstants.userNameMaxLength} characters',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              validator: (value) => UserValidator.name(
                value,
                existingNames: _users.map((u) => u.name),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('emailField'),
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              validator: (value) => UserValidator.email(
                value,
                existingEmails: _users.map((u) => u.email),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.work_outline),
              ),
              items: [
                for (final role in AppConstants.userRoles)
                  DropdownMenuItem(value: role, child: Text(role)),
              ],
              // no setState needed, nothing else on screen uses the role
              onChanged: (value) {
                if (value != null) _role = value;
              },
            ),
            const SizedBox(height: 16),
            PasswordField(
              key: const Key('passwordField'),
              controller: _passwordController,
              label: 'Password',
              helperText:
                  'At least ${AppConstants.passwordMinLength} characters, '
                  'with a letter and a number',
              validator: UserValidator.newPassword,
            ),
            const SizedBox(height: 16),
            PasswordField(
              key: const Key('confirmField'),
              controller: _confirmController,
              label: 'Confirm password',
              validator: (value) => UserValidator.confirmPassword(
                value,
                _passwordController.text,
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _createAccount(),
            ),
            if (signUpError != null) ...[
              const SizedBox(height: 16),
              Text(signUpError, style: TextStyle(color: colors.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isCreating ? null : _createAccount,
              child: _isCreating
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
