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
}
