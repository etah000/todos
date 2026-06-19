// test/features/todos/domain/todo_completion_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/todos/domain/todo_completion.dart';

void main() {
  group('TodoCompletion', () {
    final at = DateTime.fromMillisecondsSinceEpoch(1718600000000);

    test('round-trips through toMap/fromMap', () {
      final c = TodoCompletion(
        id: 'c1',
        todoId: 't1',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 30, 23, 59, 59, 999),
        completedAt: at,
        notes: 'Paid via bank',
      );
      final back = TodoCompletion.fromMap(c.toMap());
      expect(back, c);
    });

    test('coversPeriod returns true when a timestamp falls in [start, end]', () {
      final c = TodoCompletion(
        id: 'c1',
        todoId: 't1',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 30, 23, 59, 59, 999),
        completedAt: at,
      );
      expect(c.coversPeriod(DateTime(2026, 6, 15)), isTrue);
      expect(c.coversPeriod(DateTime(2026, 5, 31, 23, 59)), isFalse);
      expect(c.coversPeriod(DateTime(2026, 7, 1)), isFalse);
    });
  });
}
