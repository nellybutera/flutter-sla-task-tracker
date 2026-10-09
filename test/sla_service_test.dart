import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker/constants/app_constants.dart';
import 'package:sla_task_tracker/models/sla_status.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/services/sla_service.dart';

void main() {
  final now = DateTime(2026, 10, 10, 9);

  Task taskDue(DateTime deadline, {bool isCompleted = false}) {
    return Task(
      id: 't1',
      title: 'Write report',
      assigneeId: 'u1',
      priority: Priority.medium,
      deadline: deadline,
      isCompleted: isCompleted,
      createdAt: DateTime(2026, 10, 1),
    );
  }

  group('SlaService.statusFor', () {
    test('a completed task is Completed', () {
      final task = taskDue(now.add(const Duration(days: 5)), isCompleted: true);

      expect(SlaService.statusFor(task, now: now), SlaStatus.completed);
    });

    test('a completed task past its deadline is still Completed', () {
      final task = taskDue(
        now.subtract(const Duration(days: 3)),
        isCompleted: true,
      );

      expect(SlaService.statusFor(task, now: now), SlaStatus.completed);
    });

    test('an unfinished task past its deadline is Overdue', () {
      final task = taskDue(now.subtract(const Duration(days: 1)));

      expect(SlaService.statusFor(task, now: now), SlaStatus.overdue);
    });

    test('a deadline one minute ago is Overdue', () {
      final task = taskDue(now.subtract(const Duration(minutes: 1)));

      expect(SlaService.statusFor(task, now: now), SlaStatus.overdue);
    });

    test('a deadline equal to now is At Risk, not Overdue', () {
      final task = taskDue(now);

      expect(SlaService.statusFor(task, now: now), SlaStatus.atRisk);
    });

    test('a deadline in one hour is At Risk', () {
      final task = taskDue(now.add(const Duration(hours: 1)));

      expect(SlaService.statusFor(task, now: now), SlaStatus.atRisk);
    });

    test('47 hours 59 minutes left is At Risk', () {
      final task = taskDue(
        now.add(AppConstants.atRiskWindow - const Duration(minutes: 1)),
      );

      expect(SlaService.statusFor(task, now: now), SlaStatus.atRisk);
    });

    test('exactly the risk window left is On Track', () {
      final task = taskDue(now.add(AppConstants.atRiskWindow));

      expect(SlaService.statusFor(task, now: now), SlaStatus.onTrack);
    });

    test('a deadline far in the future is On Track', () {
      final task = taskDue(now.add(const Duration(days: 30)));

      expect(SlaService.statusFor(task, now: now), SlaStatus.onTrack);
    });

    test('uses the real clock when now is not given', () {
      final overdue = taskDue(DateTime.now().subtract(const Duration(days: 1)));
      final later = taskDue(DateTime.now().add(const Duration(days: 30)));

      expect(SlaService.statusFor(overdue), SlaStatus.overdue);
      expect(SlaService.statusFor(later), SlaStatus.onTrack);
    });
  });
}
