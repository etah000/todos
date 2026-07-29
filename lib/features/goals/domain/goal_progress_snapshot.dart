import '../../../core/utils/period_calculator.dart';
import '../../todos/domain/recurrence.dart';
import 'goal_activity.dart';
import 'goal_log.dart';
import 'goal_target_unit.dart';

class GoalProgressSnapshot {
  const GoalProgressSnapshot({
    required this.periodsElapsed,
    required this.periodsCompleted,
    required this.percent,
    required this.lifetimeTotal,
  });

  factory GoalProgressSnapshot.empty() => const GoalProgressSnapshot(
        periodsElapsed: 0,
        periodsCompleted: 0,
        percent: 0,
        lifetimeTotal: GoalLifetimeTotalBoolean(0),
      );

  factory GoalProgressSnapshot.compute({
    required GoalActivity activity,
    required DateTime now,
    required List<GoalLog> logs,
  }) {
    final per = _perFor(activity);
    final periods = <(DateTime, DateTime)>[];
    var cursor = per.anchor(activity.startDate);
    while (true) {
      final start = per.start(cursor);
      final end = per.end(cursor);
      if (start.isAfter(now)) break;
      if (!start.isBefore(activity.startDate)) {
        periods.add((start, end));
      }
      cursor = per.next(cursor);
    }
    var completed = 0;
    for (final (start, end) in periods) {
      final inPeriod = logs
          .where((l) => !l.loggedAt.isBefore(start) && !l.loggedAt.isAfter(end))
          .toList();
      if (activity.metric == ActivityMetric.boolean) {
        if (inPeriod.any((l) => l.value >= 1)) completed++;
      } else {
        final sum = inPeriod.fold<double>(0, (s, l) => s + l.value);
        if (sum >= activity.targetValue) completed++;
      }
    }
    final pct = periods.isEmpty ? 0.0 : (completed / periods.length).clamp(0.0, 1.0);
    return GoalProgressSnapshot(
      periodsElapsed: periods.length,
      periodsCompleted: completed,
      percent: pct.toDouble(),
      lifetimeTotal: _lifetime(activity, logs),
    );
  }

  static _Per _perFor(GoalActivity a) {
    final unit = a.targetUnit;
    if (unit == GoalTargetUnit.perDay) return _Per.day;
    if (unit == GoalTargetUnit.perWeek) return _Per.week;
    if (unit == GoalTargetUnit.perMonth) return _Per.month;
    return switch (a.recurrence) {
      Recurrence.none => _Per.day,
      Recurrence.daily => _Per.day,
      Recurrence.weekly => _Per.week,
      Recurrence.monthly => _Per.month,
    };
  }

  static GoalLifetimeTotal _lifetime(GoalActivity a, List<GoalLog> logs) {
    switch (a.metric) {
      case ActivityMetric.boolean:
        return GoalLifetimeTotalBoolean(logs.length);
      case ActivityMetric.count:
        return GoalLifetimeTotalCount(logs.fold<double>(0, (s, l) => s + l.value));
      case ActivityMetric.duration:
        return GoalLifetimeTotalDuration(logs.fold<int>(0, (s, l) => s + l.value.toInt()));
    }
  }

  final int periodsElapsed;
  final int periodsCompleted;
  final double percent;
  final GoalLifetimeTotal lifetimeTotal;
}

class _Per {
  const _Per({required this.start, required this.end, required this.next, required this.anchor});
  final DateTime Function(DateTime) start;
  final DateTime Function(DateTime) end;
  final DateTime Function(DateTime) next;
  final DateTime Function(DateTime) anchor;

  static final day = _Per(
    start: PeriodCalculator.dayStart,
    end: PeriodCalculator.dayEnd,
    next: (d) => DateTime(d.year, d.month, d.day + 1),
    anchor: PeriodCalculator.dayStart,
  );
  static final week = _Per(
    start: PeriodCalculator.weekStart,
    end: PeriodCalculator.weekEnd,
    next: (d) => d.add(const Duration(days: 7)),
    anchor: PeriodCalculator.weekStart,
  );
  static final month = _Per(
    start: PeriodCalculator.monthStart,
    end: PeriodCalculator.monthEnd,
    next: (d) => (d.month == 12) ? DateTime(d.year + 1, 1, 1) : DateTime(d.year, d.month + 1, 1),
    anchor: PeriodCalculator.monthStart,
  );
}

sealed class GoalLifetimeTotal {
  const GoalLifetimeTotal();
}

class GoalLifetimeTotalBoolean extends GoalLifetimeTotal {
  const GoalLifetimeTotalBoolean(this.count);
  final int count;
}

class GoalLifetimeTotalCount extends GoalLifetimeTotal {
  const GoalLifetimeTotalCount(this.total);
  final double total;
}

class GoalLifetimeTotalDuration extends GoalLifetimeTotal {
  const GoalLifetimeTotalDuration(this.totalSeconds);
  final int totalSeconds;
}