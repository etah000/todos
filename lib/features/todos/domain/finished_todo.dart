// lib/features/todos/domain/finished_todo.dart
import 'package:equatable/equatable.dart';

/// A historical record of a todo that the user completed. One-time todos
/// are deleted from the active list once recorded here; recurring ones
/// stay in the active list and only a snapshot is recorded each time the
/// user ticks them off.
class FinishedTodo extends Equatable {
  const FinishedTodo({
    required this.id,
    required this.todoId,
    required this.title,
    required this.completedAt,
    required this.recurrenceType,
  });

  final String id;
  final String todoId;
  final String title;
  final DateTime completedAt;
  final String recurrenceType;

  Map<String, Object?> toMap() => {
        'id': id,
        'todo_id': todoId,
        'title': title,
        'completed_at': completedAt.millisecondsSinceEpoch,
        'recurrence_type': recurrenceType,
      };

  factory FinishedTodo.fromMap(Map<String, Object?> m) => FinishedTodo(
        id: m['id'] as String,
        todoId: m['todo_id'] as String,
        title: m['title'] as String,
        completedAt: DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int),
        recurrenceType: m['recurrence_type'] as String,
      );

  @override
  List<Object?> get props => [id, todoId, title, completedAt, recurrenceType];
}
