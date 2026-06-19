// lib/features/todos/domain/recurrence.dart
import 'package:todos/core/utils/period_calculator.dart';

enum Recurrence {
  none('none'),
  daily('daily'),
  weekly('weekly'),
  monthly('monthly');

  const Recurrence(this.wire);
  final String wire;

  static Recurrence parse(String? wire) {
    for (final r in Recurrence.values) {
      if (r.wire == wire) return r;
    }
    return Recurrence.none;
  }

  /// The (periodStart, periodEnd) for this recurrence that contains [at].
  /// [reference] is the original due date — for Recurrence.none it determines
  /// the period directly; for periodic recurrences [at] decides the period.
  (DateTime, DateTime) periodFor(DateTime reference, {required DateTime at}) {
    switch (this) {
      case Recurrence.none:
        return (PeriodCalculator.dayStart(reference), PeriodCalculator.dayEnd(reference));
      case Recurrence.daily:
        return (PeriodCalculator.dayStart(at), PeriodCalculator.dayEnd(at));
      case Recurrence.weekly:
        return (PeriodCalculator.weekStart(at), PeriodCalculator.weekEnd(at));
      case Recurrence.monthly:
        return (PeriodCalculator.monthStart(at), PeriodCalculator.monthEnd(at));
    }
  }
}
