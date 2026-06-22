// test/features/goals/domain/goal_activity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/todos/domain/recurrence.dart';

void main() {
  group('GoalActivity', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1718600000000);

    test('round-trips through toMap/fromMap', () {
      final a = GoalActivity(
        id: 'a1',
        goalId: 'g1',
        title: 'workout',
        recurrence: Recurrence.weekly,
        recurrenceConfig: null,
        createdAt: now,
      );
      final back = GoalActivity.fromMap(a.toMap());
      expect(back, a);
    });
  });
}