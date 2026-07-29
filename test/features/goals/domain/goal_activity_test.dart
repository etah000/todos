import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_progress_snapshot.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/todos/domain/recurrence.dart';

void main() {
  GoalActivity make({
    String id = 'a1',
    String categoryId = 'c1',
    String title = 'pushup',
    Recurrence recurrence = Recurrence.daily,
    DateTime? startDate,
    double targetValue = 15,
    GoalTargetUnit targetUnit = GoalTargetUnit.perDay,
    ActivityMetric metric = ActivityMetric.count,
  }) =>
      GoalActivity(
        id: id,
        categoryId: categoryId,
        title: title,
        recurrence: recurrence,
        startDate: startDate ?? DateTime(2026, 1, 1),
        targetValue: targetValue,
        targetUnit: targetUnit,
        metric: metric,
        createdAt: DateTime(2026, 1, 1),
      );

  test('round-trips through toMap/fromMap', () {
    final a = make();
    expect(GoalActivity.fromMap(a.toMap()), equals(a));
  });

  test('fromMap reads target_value and target_unit from new columns', () {
    final a = make(targetValue: 90, targetUnit: GoalTargetUnit.perWeek);
    final restored = GoalActivity.fromMap(a.toMap());
    expect(restored.targetValue, 90);
    expect(restored.targetUnit, GoalTargetUnit.perWeek);
  });

  test('progressSnapshot is not persisted and not in Equatable.props', () {
    final a = make().copyWith(progressSnapshot: GoalProgressSnapshot.empty());
    final restored = GoalActivity.fromMap(a.toMap());
    expect(restored.progressSnapshot, isNull);
    expect(a, equals(make()));
  });

  test('copyWith updates only the named fields and preserves id/categoryId/createdAt', () {
    final a = make();
    final a2 = a.copyWith(title: 'meditate', targetValue: 20);
    expect(a2.id, 'a1');
    expect(a2.categoryId, 'c1');
    expect(a2.createdAt, DateTime(2026, 1, 1));
    expect(a2.title, 'meditate');
    expect(a2.targetValue, 20);
  });
}
