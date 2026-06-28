// test/features/todos/domain/recurrence_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/todos/domain/recurrence.dart';

void main() {
  group('Recurrence', () {
    test('serializes to/from string', () {
      for (final r in Recurrence.values) {
        expect(Recurrence.parse(r.wire), r);
      }
      expect(Recurrence.parse('unknown'), Recurrence.none);
    });

    test('periodFor returns (start, end) for a one-time due date', () {
      final due = DateTime(2026, 6, 17, 10);
      final (start, end) = Recurrence.none.periodFor(due, at: due);
      expect(start, DateTime(2026, 6, 17));
      expect(end, DateTime(2026, 6, 17, 23, 59, 59, 999));
    });

    test('periodFor daily covers the day of "at"', () {
      final t = DateTime(2026, 6, 17, 14);
      final (start, end) = Recurrence.daily.periodFor(DateTime(2026, 1, 1), at: t);
      expect(start, DateTime(2026, 6, 17));
      expect(end, DateTime(2026, 6, 17, 23, 59, 59, 999));
    });

    test('periodFor weekly covers Mon..Sun of the week containing "at"', () {
      // 2026-06-17 is a Wednesday.
      final t = DateTime(2026, 6, 17);
      final (start, end) = Recurrence.weekly.periodFor(DateTime(2026, 1, 1), at: t);
      expect(start, DateTime(2026, 6, 15));
      expect(end, DateTime(2026, 6, 21, 23, 59, 59, 999));
    });

    test('periodFor monthly covers 1st..last day of "at" month', () {
      final t = DateTime(2026, 6, 17);
      final (start, end) = Recurrence.monthly.periodFor(DateTime(2026, 1, 28), at: t);
      expect(start, DateTime(2026, 6, 1));
      expect(end, DateTime(2026, 6, 30, 23, 59, 59, 999));
    });
  });

  group('nextReminderAfter', () {
    test('returns reference when it is in the future (all recurrences)', () {
      final future = DateTime(2026, 12, 25, 9, 0);
      final now = DateTime(2026, 6, 17, 12);
      for (final r in Recurrence.values) {
        expect(r.nextReminderAfter(future, now: now), future);
      }
    });

    test('none returns null when reference is in the past', () {
      final past = DateTime(2026, 6, 10, 9, 0);
      final now = DateTime(2026, 6, 17, 12);
      expect(Recurrence.none.nextReminderAfter(past, now: now), isNull);
    });

    test('daily returns today at the same time when it has not passed', () {
      final ref = DateTime(2026, 6, 17, 9, 0);
      final now = DateTime(2026, 6, 17, 6, 0);
      expect(
        Recurrence.daily.nextReminderAfter(ref, now: now),
        DateTime(2026, 6, 17, 9, 0),
      );
    });

    test('daily returns tomorrow at the same time when today\'s has passed', () {
      final past = DateTime(2026, 6, 10, 9, 0);
      final now = DateTime(2026, 6, 17, 12);
      expect(
        Recurrence.daily.nextReminderAfter(past, now: now),
        DateTime(2026, 6, 18, 9, 0),
      );
    });

    test('weekly returns the next matching weekday at the same time', () {
      // 2026-06-12 is a Friday, now 2026-06-17 (Wednesday) 12:00 -> 2026-06-19 09:00.
      final past = DateTime(2026, 6, 12, 9, 0);
      final now = DateTime(2026, 6, 17, 12);
      expect(
        Recurrence.weekly.nextReminderAfter(past, now: now),
        DateTime(2026, 6, 19, 9, 0),
      );
    });

    test('weekly returns same day later this week when the time has not passed', () {
      // reference 2026-06-15 (Monday) 09:00, now 2026-06-15 06:00 -> same day 09:00.
      final ref = DateTime(2026, 6, 15, 9, 0);
      final now = DateTime(2026, 6, 15, 6, 0);
      expect(
        Recurrence.weekly.nextReminderAfter(ref, now: now),
        DateTime(2026, 6, 15, 9, 0),
      );
    });

    test('monthly returns this month on the same day when it has not passed', () {
      final ref = DateTime(2026, 5, 28, 9, 0);
      final now = DateTime(2026, 6, 17, 12);
      expect(
        Recurrence.monthly.nextReminderAfter(ref, now: now),
        DateTime(2026, 6, 28, 9, 0),
      );
    });

    test('monthly returns next month on the same day when this month\'s has passed', () {
      final past = DateTime(2026, 5, 10, 9, 0);
      final now = DateTime(2026, 6, 17, 12);
      expect(
        Recurrence.monthly.nextReminderAfter(past, now: now),
        DateTime(2026, 7, 10, 9, 0),
      );
    });
  });
}
