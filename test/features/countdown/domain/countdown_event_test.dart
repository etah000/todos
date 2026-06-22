// test/features/countdown/domain/countdown_event_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/countdown/domain/countdown_event.dart';

void main() {
  group('CountdownEvent', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1718600000000);

    test('round-trips through toMap/fromMap', () {
      final e = CountdownEvent(
        id: 'e1', title: 'New Year',
        targetDate: DateTime(2027, 1, 1),
        notes: 'Fireworks',
        createdAt: now, archived: false,
      );
      final back = CountdownEvent.fromMap(e.toMap());
      expect(back, e);
    });

    test('daysRemaining is positive when target is in the future', () {
      final e = CountdownEvent(
        id: 'e1', title: 'A', targetDate: DateTime(2026, 6, 27),
        createdAt: now, archived: false,
      );
      expect(e.daysRemaining(on: DateTime(2026, 6, 17)), 10);
    });

    test('daysRemaining is 0 on the target day, negative after', () {
      final e = CountdownEvent(
        id: 'e1', title: 'A', targetDate: DateTime(2026, 6, 17),
        createdAt: now, archived: false,
      );
      expect(e.daysRemaining(on: DateTime(2026, 6, 17)), 0);
      expect(e.daysRemaining(on: DateTime(2026, 6, 18)), -1);
    });
  });
}