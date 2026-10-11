import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/credential.dart';
import '../models/task.dart';
import '../models/user.dart';

/// Local persistence using SharedPreferences (tasks and users stored as JSON).
/// Owner: Member A.
class StorageService {
  static const _tasksKey = 'tasks';
  static const _usersKey = 'users';
  static const _currentUserKey = 'currentUserId';
  static const _credentialsKey = 'credentials';

  /// Demo accounts saved on first launch (password: AuthService.demoPassword).
  static const seedUsers = [
    User(
      id: 'u1',
      name: 'Alice',
      role: 'Project Lead',
      email: 'alice@demo.com',
    ),
    User(id: 'u2', name: 'Brian', role: 'Developer', email: 'brian@demo.com'),
    User(id: 'u3', name: 'Chloe', role: 'Designer', email: 'chloe@demo.com'),
  ];

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _writeTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _tasksKey,
      jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
  }

  /// Adds the task, or replaces the existing one with the same id.
  Future<void> saveTask(Task task) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }
    await _writeTasks(tasks);
  }

  Future<void> deleteTask(String id) async {
    final tasks = await loadTasks();
    tasks.removeWhere((t) => t.id == id);
    await _writeTasks(tasks);
  }

  /// Returns saved users; on first launch saves and returns 3 sample users.
  Future<List<User>> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) {
      await _writeUsers(seedUsers);
      return List.of(seedUsers);
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _writeUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  Future<void> saveUser(User user) async {
    final users = await loadUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      users.add(user);
    } else {
      users[index] = user;
    }
    await _writeUsers(users);
  }

  Future<User?> loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_currentUserKey);
    if (id == null) return null;
    final users = await loadUsers();
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  Future<void> setCurrentUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, userId);
  }

  /// For sign out. Call it before going to Sign In, otherwise
  /// Sign In sees the saved user and skips straight to the dashboard.
  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  /// Password hashes, keyed by user id. Kept apart from the users list so
  /// screens that show users never handle them.
  Future<Map<String, Credential>> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_credentialsKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map(
      (userId, value) =>
          MapEntry(userId, Credential.fromJson(value as Map<String, dynamic>)),
    );
  }

  Future<void> saveCredential(String userId, Credential credential) async {
    final credentials = await loadCredentials();
    credentials[userId] = credential;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _credentialsKey,
      jsonEncode(credentials.map((id, c) => MapEntry(id, c.toJson()))),
    );
  }
}
