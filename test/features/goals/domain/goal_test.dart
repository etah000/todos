// test/features/goals/domain/goal_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal.dart';

void main() {
  group('Goal', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1718600000000);

    test('round-trips through toMap/fromMap', () {
      final g = Goal(
        id: 'g1',
        title: 'Get fit',
        description: 'Work out regularly',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 8, 31),
        createdAt: now,
        updatedAt: now,
        archived: false,
      );
      final back = Goal.fromMap(g.toMap());
      expect(back, g);
    });

    test('isActive returns true when today is within range', () {
      final g = Goal(
        id: 'g1', title: 'A',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 8, 31),
        createdAt: now, updatedAt: now, archived: false,
      );
      expect(g.isActive(on: DateTime(2026, 6, 17)), isTrue);
      expect(g.isActive(on: DateTime(2026, 5, 31)), isFalse);
      expect(g.isActive(on: DateTime(2026, 9, 1)), isFalse);
    });
  });
}