import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker/utils/date_text.dart';

void main() {
  final now = DateTime(2026, 10, 7, 13, 0);

  group('DateText.deadline', () {
    test('shows weekday, day, month and time in the current year', () {
      final date = DateTime(2026, 10, 6, 17, 5);

      expect(DateText.deadline(date, now: now), 'Tue 6 Oct, 17:05');
    });

    test('adds the year when it is not the current year', () {
      final date = DateTime(2027, 1, 4, 9, 0);

      expect(DateText.deadline(date, now: now), 'Mon 4 Jan 2027, 09:00');
    });
  });

  group('DateText.relative', () {
    test('future deadlines use the largest whole unit', () {
      expect(
        DateText.relative(now.add(const Duration(days: 3)), now: now),
        'in 3 days',
      );
      expect(
        DateText.relative(now.add(const Duration(hours: 44)), now: now),
        'in 1 day',
      );
      expect(
        DateText.relative(now.add(const Duration(hours: 20)), now: now),
        'in 20 h',
      );
      expect(
        DateText.relative(now.add(const Duration(minutes: 45)), now: now),
        'in 45 min',
      );
    });

    test('past deadlines say how late they are', () {
      expect(
        DateText.relative(now.subtract(const Duration(days: 2)), now: now),
        '2 days late',
      );
      expect(
        DateText.relative(now.subtract(const Duration(hours: 3)), now: now),
        '3 h late',
      );
    });

    test('a deadline within the current minute is due now', () {
      expect(DateText.relative(now, now: now), 'due now');
      expect(
        DateText.relative(now.add(const Duration(seconds: 30)), now: now),
        'due now',
      );
    });
  });
}
