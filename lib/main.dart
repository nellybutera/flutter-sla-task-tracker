import 'package:flutter/material.dart';

import 'routes.dart';
import 'screens/sign_in_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TaskTrackerApp());
}

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SLA Task Tracker',
      theme: AppTheme.light,
      // home instead of initialRoute: '/signin' because initialRoute also
      // pushed '/' under it and we got a back arrow on the dashboard
      home: const SignInScreen(),
      onGenerateRoute: Routes.generate,
    );
  }
}
