// lib/features/todos/domain/todo.dart
import 'package:equatable/equatable.dart';

import 'recurrence.dart';
import 'reminder_mode.dart';

class Todo extends Equatable {
  const Todo({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    required this.recurrence,
    this.notes,
    this.dueDate,
    this.reminderTime,
    this.reminderMode = ReminderMode.notificationAndAlarm,
    this.recurrenceConfig,
  });

  final String id;
  final String title;
  final String? notes;
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final ReminderMode reminderMode;
  final Recurrence recurrence;
  final String? recurrenceConfig;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;

  Todo copyWith({
    String? title,
    String? notes,
    DateTime? dueDate,
    DateTime? reminderTime,
    ReminderMode? reminderMode,
    Recurrence? recurrence,
    String? recurrenceConfig,
    DateTime? updatedAt,
    bool? archived,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderMode: reminderMode ?? this.reminderMode,
      recurrence: recurrence ?? this.recurrence,
      recurrenceConfig: recurrenceConfig ?? this.recurrenceConfig,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'notes': notes,
        'due_date': dueDate?.millisecondsSinceEpoch,
        'reminder_time': reminderTime?.millisecondsSinceEpoch,
        'reminder_mode': reminderMode.wire,
        'recurrence_type': recurrence.wire,
        'recurrence_config': recurrenceConfig,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'archived': archived ? 1 : 0,
      };

  factory Todo.fromMap(Map<String, Object?> m) => Todo(
        id: m['id'] as String,
        title: m['title'] as String,
        notes: m['notes'] as String?,
        dueDate: (m['due_date'] as int?) == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['due_date'] as int),
        reminderTime: (m['reminder_time'] as int?) == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['reminder_time'] as int),
        reminderMode: ReminderMode.parse(m['reminder_mode'] as String?),
        recurrence: Recurrence.parse(m['recurrence_type'] as String?),
        recurrenceConfig: m['recurrence_config'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
        archived: (m['archived'] as int) == 1,
      );

  @override
  List<Object?> get props => [
        id,
        title,
        notes,
        dueDate,
        reminderTime,
        reminderMode,
        recurrence,
        recurrenceConfig,
        createdAt,
        updatedAt,
        archived,
      ];
}
