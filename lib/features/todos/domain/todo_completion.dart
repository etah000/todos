// lib/features/todos/domain/todo_completion.dart
import 'package:equatable/equatable.dart';

class TodoCompletion extends Equatable {
  const TodoCompletion({
    required this.id,
    required this.todoId,
    required this.periodStart,
    required this.periodEnd,
    required this.completedAt,
    this.notes,
  });

  final String id;
  final String todoId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime completedAt;
  final String? notes;

  bool coversPeriod(DateTime t) =>
      !t.isBefore(periodStart) && !t.isAfter(periodEnd);

  Map<String, Object?> toMap() => {
        'id': id,
        'todo_id': todoId,
        'period_start': periodStart.millisecondsSinceEpoch,
        'period_end': periodEnd.millisecondsSinceEpoch,
        'completed_at': completedAt.millisecondsSinceEpoch,
        'notes': notes,
      };

  factory TodoCompletion.fromMap(Map<String, Object?> m) => TodoCompletion(
        id: m['id'] as String,
        todoId: m['todo_id'] as String,
        periodStart: DateTime.fromMillisecondsSinceEpoch(m['period_start'] as int),
        periodEnd: DateTime.fromMillisecondsSinceEpoch(m['period_end'] as int),
        completedAt: DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int),
        notes: m['notes'] as String?,
      );

  @override
  List<Object?> get props => [id, todoId, periodStart, periodEnd, completedAt, notes];
}
