// lib/features/todos/presentation/bloc/notification_scheduler.dart
import 'package:todos/core/notifications/notification_service.dart';

abstract class NotificationScheduler {
  Future<void> schedule(String todoId, String title, DateTime when);
  Future<void> cancel(String todoId);
}

class SystemNotificationScheduler implements NotificationScheduler {
  const SystemNotificationScheduler();
  @override
  Future<void> schedule(String todoId, String title, DateTime when) async {
    await NotificationService.instance.schedule(
      id: NotificationService.idForKey('todo:$todoId'),
      title: title,
      body: 'Reminder: $title',
      when: when,
    );
  }
  @override
  Future<void> cancel(String todoId) async {
    await NotificationService.instance.cancel(NotificationService.idForKey('todo:$todoId'));
  }
}
