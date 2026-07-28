// lib/features/todos/presentation/bloc/notification_scheduler.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show DateTimeComponents;

import '../../../../core/notifications/notification_service.dart';
import '../../domain/recurrence.dart';
import '../../domain/reminder_mode.dart';

abstract class NotificationScheduler {
  Future<void> schedule(
    String todoId,
    String title,
    DateTime when, {
    Recurrence recurrence = Recurrence.none,
    ReminderMode reminderMode = ReminderMode.notificationAndAlarm,
  });
  Future<void> cancel(String todoId);
}

class SystemNotificationScheduler implements NotificationScheduler {
  const SystemNotificationScheduler();

  DateTimeComponents? _componentsFor(Recurrence r) {
    switch (r) {
      case Recurrence.none:
        return null;
      case Recurrence.daily:
        return DateTimeComponents.time;
      case Recurrence.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case Recurrence.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
    }
  }

  @override
  Future<void> schedule(
    String todoId,
    String title,
    DateTime when, {
    Recurrence recurrence = Recurrence.none,
    ReminderMode reminderMode = ReminderMode.notificationAndAlarm,
  }) async {
    try {
      final firstFire = recurrence.nextReminderAfter(when);
      if (firstFire == null) return; // past one-time reminder
      final components = _componentsFor(recurrence);
      final payload = 'todo:$todoId';
      if (reminderMode == ReminderMode.notification ||
          reminderMode == ReminderMode.notificationAndAlarm) {
        await NotificationService.instance.schedule(
          id: NotificationService.idForKey('todo:$todoId'),
          title: title,
          body: 'Reminder: $title',
          when: firstFire,
          payload: payload,
          matchDateTimeComponents: components,
        );
      }
      if (reminderMode == ReminderMode.alarm ||
          reminderMode == ReminderMode.notificationAndAlarm) {
        await NotificationService.instance.scheduleAlarm(
          id: NotificationService.idForKey('todo-alarm:$todoId'),
          title: title,
          body: 'Alarm: $title',
          when: firstFire,
          payload: payload,
          matchDateTimeComponents: components,
        );
      }
    } catch (err) {
      // Defensive: a scheduling failure must never bubble up to the bloc
      // (which would abort the surrounding todo save/refresh flow).
      debugPrint('SystemNotificationScheduler.schedule failed: $err');
    }
  }

  @override
  Future<void> cancel(String todoId) async {
    try {
      await NotificationService.instance.cancel(
        NotificationService.idForKey('todo:$todoId'),
      );
      await NotificationService.instance.cancel(
        NotificationService.idForKey('todo-alarm:$todoId'),
      );
    } catch (err) {
      debugPrint('SystemNotificationScheduler.cancel failed: $err');
    }
  }
}
