import 'package:flutter_test/flutter_test.dart';
import 'package:todos/core/utils/period_calculator.dart';

void main() {
  group('PeriodCalculator', () {
    test('dayStart returns midnight of the given date', () {
      final t = DateTime(2026, 6, 17, 14, 32);
      expect(PeriodCalculator.dayStart(t), DateTime(2026, 6, 17));
    });

    test('dayEnd returns 23:59:59.999 of the given date', () {
      final t = DateTime(2026, 6, 17, 14, 32);
      expect(PeriodCalculator.dayEnd(t), DateTime(2026, 6, 17, 23, 59, 59, 999));
    });

    test('weekStart returns Monday of the same week', () {
      // 2026-06-17 is a Wednesday.
      final wed = DateTime(2026, 6, 17);
      expect(PeriodCalculator.weekStart(wed), DateTime(2026, 6, 15)); // Monday
    });

    test('weekStart on a Sunday still returns that week\'s Monday', () {
      // 2026-06-21 is a Sunday -> Monday 2026-06-15.
      final sun = DateTime(2026, 6, 21);
      expect(PeriodCalculator.weekStart(sun), DateTime(2026, 6, 15));
    });

    test('weekEnd returns the following Sunday 23:59:59.999', () {
      final wed = DateTime(2026, 6, 17);
      expect(PeriodCalculator.weekEnd(wed), DateTime(2026, 6, 21, 23, 59, 59, 999));
    });

    test('monthStart returns the 1st at 00:00', () {
      expect(
        PeriodCalculator.monthStart(DateTime(2026, 6, 17)),
        DateTime(2026, 6, 1),
      );
    });

    test('monthEnd returns the last day of the month at 23:59:59.999', () {
      expect(
        PeriodCalculator.monthEnd(DateTime(2026, 6, 17)),
        DateTime(2026, 6, 30, 23, 59, 59, 999),
      );
      // February in a non-leap year.
      expect(
        PeriodCalculator.monthEnd(DateTime(2026, 2, 10)),
        DateTime(2026, 2, 28, 23, 59, 59, 999),
      );
    });
  });
}
