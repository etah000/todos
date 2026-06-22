// test/features/goals/domain/activity_completion_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/activity_completion.dart';

void main() {
  group('ActivityCompletion', () {
    final at = DateTime.fromMillisecondsSinceEpoch(1718600000000);
    test('round-trips through toMap/fromMap', () {
      final c = ActivityCompletion(
        id: 'c1', activityId: 'a1',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 30, 23, 59, 59, 999),
        completedAt: at, notes: 'felt good',
      );
      final back = ActivityCompletion.fromMap(c.toMap());
      expect(back, c);
    });
  });
}