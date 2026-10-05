import 'package:flutter/material.dart';

/// OWNER: Member A. TODO: replace this placeholder with the real screen.
/// Temporary button below lets the team reach the rest of the app now.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In / User Selection')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          child: const Text('Continue (placeholder)'),
        ),
      ),
    );
  }
}
