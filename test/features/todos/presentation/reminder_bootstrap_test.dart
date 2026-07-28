// test/features/todos/presentation/reminder_bootstrap_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/todos/data/todo_repository.dart';
import 'package:todos/features/todos/domain/recurrence.dart';
import 'package:todos/features/todos/domain/reminder_mode.dart';
import 'package:todos/features/todos/domain/todo.dart';
import 'package:todos/features/todos/presentation/bloc/notification_scheduler.dart';
import 'package:todos/features/todos/presentation/reminder_bootstrap.dart';

class _MockScheduler extends Mock implements NotificationScheduler {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    registerFallbackValue(Recurrence.none);
    registerFallbackValue(ReminderMode.notificationAndAlarm);
  });

  group('rescheduleAllReminders', () {
    late AppDatabase db;
    late TodoRepository repo;
    late _MockScheduler scheduler;

    setUp(() async {
      db = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      repo = TodoRepository(db);
      scheduler = _MockScheduler();
      when(() => scheduler.cancel(any())).thenAnswer((_) async {});
      when(
        () => scheduler.schedule(
          any(),
          any(),
          any(),
          recurrence: any(named: 'recurrence'),
          reminderMode: any(named: 'reminderMode'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() async => db.close());

    Future<void> insert(Todo t) => repo.insert(t);

    test('schedules every todo with a reminderTime (future or recurring)',
        () async {
      final now = DateTime(2026, 6, 1, 8);
      await insert(
        Todo(
          id: 'future',
          title: 'future',
          reminderTime: now.add(const Duration(days: 7)),
          reminderMode: ReminderMode.alarm,
          recurrence: Recurrence.none,
          createdAt: now,
          updatedAt: now,
          archived: false,
        ),
      );
      await insert(
        Todo(
          id: 'past-monthly',
          title: 'past-monthly',
          reminderTime: DateTime(2026, 5, 28, 9), // past, recurring
          recurrence: Recurrence.monthly,
          createdAt: now,
          updatedAt: now,
          archived: false,
        ),
      );
      await insert(
        Todo(
          id: 'no-reminder',
          title: 'no-reminder',
          reminderTime: null,
          recurrence: Recurrence.none,
          createdAt: now,
          updatedAt: now,
          archived: false,
        ),
      );

      await rescheduleAllReminders(db, scheduler: scheduler);

      verify(() => scheduler.cancel('future')).called(1);
      verify(
        () => scheduler.schedule(
          'future',
          any(),
          any(),
          recurrence: Recurrence.none,
          reminderMode: ReminderMode.alarm,
        ),
      ).called(1);

      verify(() => scheduler.cancel('past-monthly')).called(1);
      verify(
        () => scheduler.schedule(
          'past-monthly',
          any(),
          any(),
          recurrence: Recurrence.monthly,
          reminderMode: ReminderMode.notificationAndAlarm,
        ),
      ).called(1);

      verifyNever(() => scheduler.cancel('no-reminder'));
      verifyNever(
        () => scheduler.schedule(
          'no-reminder',
          any(),
          any(),
          recurrence: any(named: 'recurrence'),
          reminderMode: any(named: 'reminderMode'),
        ),
      );
    });

    test('one failing todo does not abort the rest', () async {
      final now = DateTime(2026, 6, 1, 8);
      await insert(
        Todo(
          id: 'bad',
          title: 'bad',
          reminderTime: now.add(const Duration(hours: 1)),
          recurrence: Recurrence.none,
          createdAt: now,
          updatedAt: now,
          archived: false,
        ),
      );
      await insert(
        Todo(
          id: 'good',
          title: 'good',
          reminderTime: now.add(const Duration(hours: 2)),
          recurrence: Recurrence.none,
          createdAt: now,
          updatedAt: now,
          archived: false,
        ),
      );

      when(() => scheduler.cancel('bad')).thenThrow(Exception('boom'));

      await rescheduleAllReminders(db, scheduler: scheduler);

      verify(() => scheduler.cancel('good')).called(1);
      verify(
        () => scheduler.schedule(
          'good',
          any(),
          any(),
          recurrence: any(named: 'recurrence'),
          reminderMode: any(named: 'reminderMode'),
        ),
      ).called(1);
    });
  });
}
