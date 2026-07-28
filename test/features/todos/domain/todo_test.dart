// test/features/todos/domain/todo_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/todos/domain/recurrence.dart';
import 'package:todos/features/todos/domain/reminder_mode.dart';
import 'package:todos/features/todos/domain/todo.dart';

void main() {
  group('Todo', () {
    final created = DateTime.fromMillisecondsSinceEpoch(1718600000000);

    test('round-trips through toMap/fromMap', () {
      final t = Todo(
        id: 'a1',
        title: 'Pay rent',
        notes: 'Bank transfer',
        dueDate: DateTime(2026, 6, 28),
        reminderTime: DateTime(2026, 6, 28, 9),
        reminderMode: ReminderMode.alarm,
        recurrence: Recurrence.monthly,
        recurrenceConfig: '{"dayOfMonth":28}',
        createdAt: created,
        updatedAt: created,
        archived: false,
      );
      final m = t.toMap();
      final back = Todo.fromMap(m);
      expect(back, t);
      expect(m['reminder_mode'], 'alarm');
    });

    test('copyWith updates only the given fields', () {
      final t = Todo(
        id: 'a1',
        title: 'A',
        createdAt: created,
        updatedAt: created,
        archived: false,
        recurrence: Recurrence.none,
      );
      final t2 = t.copyWith(title: 'B', archived: true);
      expect(t2.id, 'a1');
      expect(t2.title, 'B');
      expect(t2.archived, true);
      expect(t2.recurrence, Recurrence.none);
      expect(t2.reminderMode, ReminderMode.notificationAndAlarm);
    });

    test('fromMap tolerates null optional fields', () {
      final m = {
        'id': 'a1',
        'title': 'A',
        'notes': null,
        'due_date': null,
        'reminder_time': null,
        'reminder_mode': null,
        'recurrence_type': 'none',
        'recurrence_config': null,
        'created_at': created.millisecondsSinceEpoch,
        'updated_at': created.millisecondsSinceEpoch,
        'archived': 0,
      };
      final t = Todo.fromMap(m);
      expect(t.notes, isNull);
      expect(t.dueDate, isNull);
      expect(t.reminderTime, isNull);
      expect(t.reminderMode, ReminderMode.notificationAndAlarm);
    });
  });

  group('ReminderMode', () {
    test('parses known wire values and defaults unknown values', () {
      expect(ReminderMode.parse('notification'), ReminderMode.notification);
      expect(ReminderMode.parse('alarm'), ReminderMode.alarm);
      expect(
        ReminderMode.parse('notification_and_alarm'),
        ReminderMode.notificationAndAlarm,
      );
      expect(ReminderMode.parse(null), ReminderMode.notificationAndAlarm);
      expect(ReminderMode.parse('bad'), ReminderMode.notificationAndAlarm);
    });
  });
}
