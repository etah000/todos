# Todo Reminder Modes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix Android scheduled reminder delivery and add notification, alarm, and notification-plus-alarm reminder modes.

**Architecture:** Add a small domain enum, persist it on todos, pass it through BLoC events into the scheduler, and map modes to `flutter_local_notifications` schedule modes. Android receiver declarations complete plugin integration.

**Tech Stack:** Flutter, Dart, sqflite, flutter_local_notifications 17.2.4, bloc_test, mocktail.

## Global Constraints

Use standard Dart formatting. Keep feature code under `lib/features/todos`. Preserve existing local-first storage patterns. Add focused tests before production changes.

---

### Task 1: Domain And Persistence

**Files:**
- Create: `lib/features/todos/domain/reminder_mode.dart`
- Modify: `lib/core/database/schema.dart`
- Modify: `lib/core/database/migrations.dart`
- Modify: `lib/features/todos/domain/todo.dart`
- Test: `test/features/todos/domain/todo_test.dart`
- Test: `test/core/database/database_test.dart`

**Interfaces:**
- Produces: `enum ReminderMode { notification, alarm, notificationAndAlarm }`
- Produces: `ReminderMode.parse(String? wire)`
- Produces: `Todo.reminderMode`

- [ ] Write failing serialization and migration tests.
- [ ] Run focused tests and confirm they fail because `ReminderMode` and `reminder_mode` do not exist.
- [ ] Add enum, schema column, version 3 migration, create-table column, and `Todo` mapping.
- [ ] Run focused tests and confirm they pass.

### Task 2: Scheduling Modes

**Files:**
- Modify: `lib/core/notifications/notification_service.dart`
- Modify: `lib/features/todos/presentation/bloc/notification_scheduler.dart`
- Modify: `lib/features/todos/presentation/bloc/todo_bloc.dart`
- Modify: `lib/features/todos/presentation/bloc/todo_event.dart`
- Test: `test/features/todos/presentation/bloc/todo_bloc_notifications_test.dart`
- Test: `test/features/todos/presentation/bloc/todo_bloc_test.dart`

**Interfaces:**
- Consumes: `ReminderMode`
- Produces: `NotificationScheduler.schedule(..., reminderMode: ReminderMode.notificationAndAlarm)`
- Produces: `NotificationService.schedule(..., androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle)`

- [ ] Write failing tests for forwarding `reminderMode` and scheduling distinct notification/alarm ids.
- [ ] Run focused tests and confirm they fail on missing parameters.
- [ ] Extend events, bloc, scheduler, and service.
- [ ] Run focused tests and confirm they pass.

### Task 3: Android Manifest And UI

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `lib/features/todos/presentation/pages/todo_form_page.dart`
- Modify: `lib/features/todos/presentation/widgets/todo_tile.dart`
- Test: existing focused tests

**Interfaces:**
- Consumes: `Todo.reminderMode`
- Produces: manifest receivers for `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver`

- [ ] Add receiver declarations under `<application>`.
- [ ] Add reminder mode dropdown when reminder time is present.
- [ ] Include reminder mode in todo tile subtitle when useful.
- [ ] Run formatter, analyzer, and focused tests.
