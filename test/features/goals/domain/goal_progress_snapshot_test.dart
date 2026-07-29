import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_log.dart';
import 'package:todos/features/goals/domain/goal_progress_snapshot.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/todos/domain/recurrence.dart';

void main() {
  GoalActivity make({
    DateTime? startDate,
    double targetValue = 1,
    GoalTargetUnit targetUnit = GoalTargetUnit.perDay,
    ActivityMetric metric = ActivityMetric.boolean,
    Recurrence recurrence = Recurrence.daily,
  }) =>
      GoalActivity(
        id: 'a1', categoryId: 'c1', title: 't',
        recurrence: recurrence,
        startDate: startDate ?? DateTime(2026, 7, 1),
        targetValue: targetValue,
        targetUnit: targetUnit,
        metric: metric,
        createdAt: startDate ?? DateTime(2026, 7, 1),
      );

  GoalLog log(DateTime when, double value) => GoalLog(
        id: 'l', goalActivityId: 'a1', value: value,
        loggedAt: when, createdAt: when,
      );

  test('boolean: each day with one event counts as completed', () {
    final activity = make();
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 7, 5, 23, 59),
      logs: [
        log(DateTime(2026, 7, 1, 9), 1),
        log(DateTime(2026, 7, 3, 9), 1),
      ],
    );
    expect(snap.periodsElapsed, 5);
    expect(snap.periodsCompleted, 2);
    expect(snap.percent, closeTo(2 / 5, 1e-9));
    expect((snap.lifetimeTotal as GoalLifetimeTotalBoolean).count, 2);
  });

  test('count: perDay target of 15 sums daily logs', () {
    final activity = make(targetValue: 15, targetUnit: GoalTargetUnit.perDay, metric: ActivityMetric.count);
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 7, 3, 23, 59),
      logs: [
        log(DateTime(2026, 7, 1, 9), 10),
        log(DateTime(2026, 7, 2, 9), 20),
        log(DateTime(2026, 7, 3, 9), 5),
      ],
    );
    expect(snap.periodsElapsed, 3);
    expect(snap.periodsCompleted, 1);
    expect((snap.lifetimeTotal as GoalLifetimeTotalCount).total, 35);
  });

  test('perWeek target sums across the week', () {
    final activity = make(
      targetValue: 90,
      targetUnit: GoalTargetUnit.perWeek,
      metric: ActivityMetric.count,
      startDate: DateTime(2026, 6, 29), // Mon
    );
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 7, 12, 23, 59),  // Sun — end of week 2
      logs: [
        log(DateTime(2026, 7, 1), 50),
        log(DateTime(2026, 7, 4), 60),  // week 1: 110 ≥ 90
        log(DateTime(2026, 7, 8), 30),
        log(DateTime(2026, 7, 11), 40), // week 2: 70 < 90
      ],
    );
    expect(snap.periodsCompleted, 1);
    expect((snap.lifetimeTotal as GoalLifetimeTotalCount).total, 180);
  });

  test('perPeriod falls back to recurrence=weekly', () {
    final activity = make(
      targetUnit: GoalTargetUnit.perPeriod,
      metric: ActivityMetric.count,
      targetValue: 1,
      recurrence: Recurrence.weekly,
      startDate: DateTime(2026, 7, 6),
    );
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 7, 19, 23, 59),
      logs: [log(DateTime(2026, 7, 8), 1)],
    );
    expect(snap.periodsElapsed, 2);
    expect(snap.periodsCompleted, 1);
  });

  test('duration metric sums seconds', () {
    final activity = make(metric: ActivityMetric.duration, targetValue: 30, targetUnit: GoalTargetUnit.perDay);
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 7, 1, 23, 59),
      logs: [log(DateTime(2026, 7, 1, 9), 45)],
    );
    expect(snap.periodsCompleted, 1);
    expect((snap.lifetimeTotal as GoalLifetimeTotalDuration).totalSeconds, 45);
  });

  test('future periods are not counted', () {
    final activity = make(startDate: DateTime(2026, 7, 10));
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 7, 5),
      logs: const [],
    );
    expect(snap.periodsElapsed, 0);
    expect(snap.percent, 0.0);
  });

  test('month-end edge: monthly goal with start_date=Jan 31', () {
    final activity = make(
      targetUnit: GoalTargetUnit.perMonth,
      metric: ActivityMetric.boolean,
      targetValue: 1,
      startDate: DateTime(2026, 1, 31),
    );
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 2, 28, 23, 59),
      logs: [log(DateTime(2026, 2, 1), 1)],
    );
    expect(snap.periodsElapsed, 1);
    expect(snap.periodsCompleted, 1);
  });
}