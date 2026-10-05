import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

void main() {
  final task = Task(
    id: 't1',
    title: 'Write report',
    assigneeId: 'u1',
    priority: Priority.high,
    deadline: DateTime(2026, 10, 10, 12),
    createdAt: DateTime(2026, 10, 1),
  );

  test('Task survives toJson / fromJson', () {
    final copy = Task.fromJson(task.toJson());
    expect(copy.id, 't1');
    expect(copy.priority, Priority.high);
    expect(copy.deadline, task.deadline);
  });

  test('StorageService saves, updates and deletes tasks', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.saveTask(task);
    expect((await storage.loadTasks()).length, 1);
    await storage.saveTask(task.copyWith(title: 'Edited'));
    final tasks = await storage.loadTasks();
    expect(tasks.length, 1);
    expect(tasks.first.title, 'Edited');
    await storage.deleteTask('t1');
    expect(await storage.loadTasks(), isEmpty);
  });

  test('loadUsers seeds sample users on first launch', () async {
    SharedPreferences.setMockInitialValues({});
    final users = await StorageService().loadUsers();
    expect(users.length, 3);
  });
}
