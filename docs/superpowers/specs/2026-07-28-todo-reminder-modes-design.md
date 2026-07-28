# Todo Reminder Modes Design

## Goal

Todo reminders must reliably trigger on Android and support three reminder modes: notification, alarm, and notification plus alarm.

## Current Behavior

Reminders are scheduled through `flutter_local_notifications.zonedSchedule` as high-priority local notifications. The Android manifest declares notification and alarm permissions, but it does not declare the scheduled notification receivers required by `flutter_local_notifications` 16+.

## Design

Add a `ReminderMode` domain enum with wire values `notification`, `alarm`, and `notificationAndAlarm`. Store it on each todo as `reminder_mode`, defaulting existing todos to `notificationAndAlarm`.

Keep `TodoBloc` responsible for deciding whether a reminder should be scheduled. Extend `NotificationScheduler.schedule` to accept the reminder mode. `SystemNotificationScheduler` schedules:

- `notification`: one normal scheduled notification.
- `alarm`: one alarm-clock scheduled notification.
- `notificationAndAlarm`: both schedules, using stable but distinct notification ids.

The Android manifest must declare `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` inside `<application>`, so scheduled notifications can be shown and restored after package replacement or reboot.

## UI

The todo form exposes a reminder mode dropdown only when a reminder time is set. New todos default to notification plus alarm. Existing todos without a stored mode also default to notification plus alarm.

## Testing

Add tests for enum parsing, todo serialization, database migration/create schema, BLoC forwarding of reminder mode, and scheduler id/mode behavior. Keep existing reminder behavior for skipped past one-time reminders and recurring reminders.
