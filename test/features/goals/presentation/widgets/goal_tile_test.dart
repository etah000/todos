import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_progress_snapshot.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/goals/presentation/widgets/goal_tile.dart';
import 'package:todos/features/todos/domain/recurrence.dart';

void main() {
  GoalActivity activity({
    String title = 'pushup',
    double targetValue = 15,
    GoalTargetUnit targetUnit = GoalTargetUnit.perDay,
    ActivityMetric metric = ActivityMetric.count,
    GoalProgressSnapshot? snapshot,
  }) =>
      GoalActivity(
        id: 'a1', categoryId: 'c1', title: title,
        recurrence: Recurrence.daily,
        startDate: DateTime(2026, 7, 1),
        targetValue: targetValue, targetUnit: targetUnit, metric: metric,
        createdAt: DateTime(2026, 7, 1),
        progressSnapshot: snapshot,
      );

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders title and target expression chip', (tester) async {
    await tester.pumpWidget(host(GoalTile(activity: activity(), onTap: (_) {})));
    expect(find.text('pushup'), findsOneWidget);
    expect(find.text('15 / day'), findsOneWidget);
  });

  testWidgets('renders lifetime total for boolean metric', (tester) async {
    await tester.pumpWidget(host(GoalTile(
      activity: activity(
        metric: ActivityMetric.boolean,
        targetValue: 1,
        snapshot: const GoalProgressSnapshot(
          periodsElapsed: 5, periodsCompleted: 2, percent: 0.4,
          lifetimeTotal: GoalLifetimeTotalBoolean(2),
        ),
      ),
      onTap: (_) {},
    )));
    expect(find.text('2 days'), findsOneWidget);
    expect(find.text('2 of 5 periods completed'), findsOneWidget);
  });

  testWidgets('renders lifetime total for count metric', (tester) async {
    await tester.pumpWidget(host(GoalTile(
      activity: activity(snapshot: const GoalProgressSnapshot(
        periodsElapsed: 3, periodsCompleted: 1, percent: 0.33,
        lifetimeTotal: GoalLifetimeTotalCount(35),
      )),
      onTap: (_) {},
    )));
    expect(find.text('35 total'), findsOneWidget);
  });

  testWidgets('renders lifetime total for duration metric', (tester) async {
    await tester.pumpWidget(host(GoalTile(
      activity: activity(
        metric: ActivityMetric.duration,
        targetValue: 1800,
        snapshot: const GoalProgressSnapshot(
          periodsElapsed: 1, periodsCompleted: 1, percent: 1.0,
          lifetimeTotal: GoalLifetimeTotalDuration(7200),
        ),
      ),
      onTap: (_) {},
    )));
    expect(find.text('2h 0m'), findsOneWidget);
  });

  testWidgets('taps onTap', (tester) async {
    GoalActivity? tapped;
    await tester.pumpWidget(host(GoalTile(activity: activity(), onTap: (a) => tapped = a)));
    await tester.tap(find.text('pushup'));
    expect(tapped, isNotNull);
    expect(tapped!.id, 'a1');
  });
}
