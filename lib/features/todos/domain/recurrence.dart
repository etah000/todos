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

  /// Next reminder datetime at/after [now] that carries [reference]'s
  /// time-of-day (and weekday for [weekly], day-of-month for [monthly]).
  ///
  /// Used to compute the first fire time of a recurring reminder. Returns
  /// [reference] itself when it is already in the future (for all recurrences
  /// including [none]). Returns null for [none] when [reference] is in the
  /// past — a missed one-time reminder is not re-armed.
  DateTime? nextReminderAfter(DateTime reference, {DateTime? now}) {
    final at = now ?? DateTime.now();
    if (!reference.isBefore(at)) return reference;
    final hour = reference.hour;
    final minute = reference.minute;
    switch (this) {
      case Recurrence.none:
        return null;
      case Recurrence.daily:
        final today = DateTime(at.year, at.month, at.day, hour, minute);
        return today.isBefore(at)
            ? today.add(const Duration(days: 1))
            : today;
      case Recurrence.weekly:
        final base = DateTime(at.year, at.month, at.day, hour, minute);
        final delta = (reference.weekday - at.weekday) % 7;
        var candidate = base.add(Duration(days: delta));
        if (candidate.isBefore(at)) {
          candidate = candidate.add(const Duration(days: 7));
        }
        return candidate;
      case Recurrence.monthly:
        var year = at.year;
        var month = at.month;
        for (var i = 0; i < 24; i++) {
          if (reference.day <= DateTime(year, month + 1, 0).day) {
            final candidate = DateTime(year, month, reference.day, hour, minute);
            if (!candidate.isBefore(at)) return candidate;
          }
          month += 1;
          if (month > 12) {
            month = 1;
            year += 1;
          }
        }
        return null;
    }
  }
}
