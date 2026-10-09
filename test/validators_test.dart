import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker/services/validators.dart';

void main() {
  group('Validators.title', () {
    test('returns null for a valid title', () {
      expect(Validators.title('Create homepage'), isNull);
    });

    test('rejects an empty title', () {
      expect(Validators.title(''), 'Title is required.');
    });

    test('rejects a title shorter than the minimum', () {
      expect(Validators.title('Hi'), contains('at least'));
    });

    test('accepts a title at the minimum length', () {
      expect(Validators.title('ABC'), isNull);
    });

    test('rejects a title longer than the maximum', () {
      final title = 'A' * 61;

      expect(Validators.title(title), contains('at most'));
    });

    test('accepts a title at the maximum length', () {
      final title = 'A' * 60;

      expect(Validators.title(title), isNull);
    });
  });

  group('Validators.description', () {
    test('allows an empty description', () {
      expect(Validators.description(''), isNull);
    });

    test('accepts a description at the maximum length', () {
      final description = 'A' * 300;

      expect(Validators.description(description), isNull);
    });

    test('rejects a description over the maximum length', () {
      final description = 'A' * 301;

      expect(Validators.description(description), contains('at most'));
    });
  });

  group('Validators.assignee', () {
    test('accepts a selected assignee', () {
      expect(Validators.assignee('u1'), isNull);
    });

    test('rejects null assignee', () {
      expect(Validators.assignee(null), 'Please select an assignee.');
    });

    test('rejects an empty assignee', () {
      expect(Validators.assignee(''), 'Please select an assignee.');
    });
  });

  group('Validators.deadline', () {
    final now = DateTime(2026, 10, 8, 12);

    test('accepts a future deadline for a new task', () {
      final deadline = DateTime(2026, 10, 10, 12);

      expect(Validators.deadline(deadline, isNewTask: true, now: now), isNull);
    });

    test('rejects a missing deadline', () {
      expect(
        Validators.deadline(null, isNewTask: true, now: now),
        'Please select a deadline.',
      );
    });

    test('rejects a past deadline for a new task', () {
      final deadline = DateTime(2026, 10, 7, 12);

      expect(
        Validators.deadline(deadline, isNewTask: true, now: now),
        'Deadline cannot be in the past.',
      );
    });

    test('allows an existing task to keep its old deadline', () {
      final oldDeadline = DateTime(2026, 10, 1, 12);

      expect(
        Validators.deadline(oldDeadline, isNewTask: false, now: now),
        isNull,
      );
    });
  });
}
