import 'package:flutter/material.dart';

import 'models/task.dart';
import 'screens/home_shell.dart';
import 'screens/sign_in_screen.dart';
import 'screens/task_details_screen.dart';
import 'screens/task_form_screen.dart';

/// Route names agreed by the team. Owner: Member B.
class Routes {
  static const signIn = '/signin';
  static const dashboard = '/dashboard';
  static const tasks = '/tasks';
  static const team = '/team';
  static const taskDetails = '/task-details'; // argument: Task
  static const taskForm = '/task-form'; // argument: Task? (null = create)

  static Route<dynamic> generate(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case dashboard:
        page = const HomeShell(initialIndex: 0);
        break;
      case tasks:
        page = const HomeShell(initialIndex: 1);
        break;
      case team:
        page = const HomeShell(initialIndex: 2);
        break;
      case taskDetails:
        page = TaskDetailsScreen(task: settings.arguments as Task);
        break;
      case taskForm:
        page = TaskFormScreen(task: settings.arguments as Task?);
        break;
      case signIn:
      default:
        page = const SignInScreen();
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
