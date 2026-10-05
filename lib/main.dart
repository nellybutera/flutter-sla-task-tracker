import 'package:flutter/material.dart';

import 'routes.dart';
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
      initialRoute: Routes.signIn,
      onGenerateRoute: Routes.generate,
    );
  }
}
