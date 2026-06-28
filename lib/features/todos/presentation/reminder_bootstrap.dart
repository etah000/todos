// lib/features/todos/presentation/reminder_bootstrap.dart
import 'package:flutter/foundation.dart';

import '../../../core/database/database.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';
import 'bloc/notification_scheduler.dart';

/// Re-schedules every todo with a future reminder on every cold start.
///
/// AlarmManager loses all scheduled alarms on device reboot, and
/// recurring (daily/weekly/monthly) reminders are also re-established here
/// since `matchDateTimeComponents` itself doesn't survive reboot. Each todo's
/// notification id is stable (see [NotificationService.idForKey]) so
/// cancel-then-schedule is safe and idempotent — no duplicate alarms.
Future<void> rescheduleAllReminders(
  AppDatabase db, {
  NotificationScheduler scheduler = const SystemNotificationScheduler(),
}) async {
  try {
    final List<Todo> todos = await TodoRepository(db).getAll();
    for (final todo in todos) {
      final r = todo.reminderTime;
      if (r == null) continue;
      try {
        await scheduler.cancel(todo.id);
        await scheduler.schedule(
          todo.id,
          todo.title,
          r,
          recurrence: todo.recurrence,
        );
      } catch (err) {
        // One bad todo must not abort the rest of the bootstrap.
        debugPrint('reminder_bootstrap: failed to reschedule ${todo.id}: $err');
      }
    }
  } catch (err) {
    debugPrint('reminder_bootstrap: failed to load todos: $err');
  }
}
