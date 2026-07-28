import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal_log.dart';

void main() {
  test('round-trips through toMap/fromMap', () {
    final l = GoalLog(
      id: 'l1', goalActivityId: 'a1', value: 15.0, notes: 'felt good',
      loggedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      createdAt: DateTime.fromMillisecondsSinceEpoch(2000),
    );
    expect(GoalLog.fromMap(l.toMap()), equals(l));
  });

  test('notes is optional', () {
    final l = GoalLog(
      id: 'l1', goalActivityId: 'a1', value: 1.0,
      loggedAt: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    );
    expect(l.notes, isNull);
  });

  test('copyWith updates only the named fields', () {
    final l = GoalLog(
      id: 'l1', goalActivityId: 'a1', value: 1.0,
      loggedAt: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    );
    final l2 = l.copyWith(value: 2.0);
    expect(l2.id, 'l1');
    expect(l2.value, 2.0);
    expect(l2.loggedAt, DateTime(2026, 1, 1));
  });
}