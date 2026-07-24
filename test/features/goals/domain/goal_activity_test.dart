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

    test('round-trips count metric and totals', () {
      final a = GoalActivity(
        id: 'a2',
        goalId: 'g1',
        title: 'push-ups',
        recurrence: Recurrence.daily,
        createdAt: now,
        metric: ActivityMetric.count,
        totalCount: 42,
      );
      final back = GoalActivity.fromMap(a.toMap());
      expect(back.metric, ActivityMetric.count);
      expect(back.totalCount, 42);
      expect(back.totalSeconds, 0);
    });

    test('round-trips duration metric and totals', () {
      final a = GoalActivity(
        id: 'a3',
        goalId: 'g1',
        title: 'study',
        recurrence: Recurrence.weekly,
        createdAt: now,
        metric: ActivityMetric.duration,
        totalSeconds: 7200,
      );
      final back = GoalActivity.fromMap(a.toMap());
      expect(back.metric, ActivityMetric.duration);
      expect(back.totalSeconds, 7200);
    });

    test('old rows without metric default to boolean', () {
      final m = {
        'id': 'a4',
        'goal_id': 'g1',
        'title': 'old',
        'recurrence_type': 'daily',
        'recurrence_config': null,
        'created_at': now.millisecondsSinceEpoch,
        // No metric / totalCount / totalSeconds — pre-v2 schema.
      };
      final a = GoalActivity.fromMap(m);
      expect(a.metric, ActivityMetric.boolean);
      expect(a.totalCount, 0);
      expect(a.totalSeconds, 0);
    });
  });
}