import 'dart:async';

import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/user_validator.dart';
import '../widgets/error_view.dart';
import '../widgets/password_field.dart';

class SignInScreen extends StatefulWidget {
  final StorageService? storage;

  const SignInScreen({super.key, this.storage});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const double _maxContentWidth = 480;

  late final StorageService _storage = widget.storage ?? StorageService();
  late final AuthService _auth = AuthService(storage: _storage);
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isCheckingSession = true;
  bool _isSigningIn = false;
  String? _loadError;
  String? _signInError;

  @override
  void initState() {
    super.initState();
    unawaited(_checkSavedSession());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // someone already signed in on this phone goes straight to the dashboard
  Future<void> _checkSavedSession() async {
    try {
      final currentUser = await _storage.loadCurrentUser();
      if (!mounted) return;
      if (currentUser != null) {
        _openDashboard();
        return;
      }
      setState(() => _isCheckingSession = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCheckingSession = false;
        _loadError = 'Could not open the app. Please try again.';
      });
    }
  }

  void _retry() {
    setState(() {
      _isCheckingSession = true;
      _loadError = null;
    });
    unawaited(_checkSavedSession());
  }

  Future<void> _signIn() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isSigningIn = true;
      _signInError = null;
    });
    try {
      await _auth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      _openDashboard();
    } on AuthException catch (error) {
      _showSignInError(error.message);
    } catch (_) {
      _showSignInError('Could not sign in. Please try again.');
    }
  }

  void _showSignInError(String message) {
    if (!mounted) return;
    setState(() {
      _isSigningIn = false;
      _signInError = message;
    });
  }

  void _clearSignInError(String _) {
    if (_signInError != null) setState(() => _signInError = null);
  }

  void _openSignUp() {
    unawaited(Navigator.pushNamed(context, Routes.signUp));
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
    if (_isCheckingSession) {
      return const Center(child: CircularProgressIndicator());
    }
    final loadError = _loadError;
    if (loadError != null) {
      return ErrorView(message: loadError, onRetry: _retry);
    }
    final signInError = _signInError;
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            const SizedBox(height: 32),
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
              autofillHints: const [AutofillHints.email],
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              validator: UserValidator.email,
              onChanged: _clearSignInError,
            ),
            const SizedBox(height: 16),
            PasswordField(
              key: const Key('passwordField'),
              controller: _passwordController,
              label: 'Password',
              validator: UserValidator.signInPassword,
              textInputAction: TextInputAction.done,
              onChanged: _clearSignInError,
              onFieldSubmitted: (_) => _signIn(),
            ),
            if (signInError != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.error_outline, color: colors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      signInError,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSigningIn ? null : _signIn,
              child: _isSigningIn
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign in'),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: _openSignUp,
                  child: const Text('Create one'),
                ),
              ],
            ),
          ],
        ),
      ),
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
          "Sign in to see your team's tasks",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
