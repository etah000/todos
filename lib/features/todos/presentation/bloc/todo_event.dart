// lib/features/todos/presentation/bloc/todo_event.dart
import 'package:equatable/equatable.dart';

import '../../domain/recurrence.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();
  @override
  List<Object?> get props => [];
}

class TodosSubscriptionRequested extends TodoEvent {
  const TodosSubscriptionRequested();
}

class TodoCreated extends TodoEvent {
  const TodoCreated({
    required this.title,
    this.notes,
    this.dueDate,
    this.reminderTime,
    this.recurrence = Recurrence.none,
    this.recurrenceConfig,
  });

  final String title;
  final String? notes;
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final Recurrence recurrence;
  final String? recurrenceConfig;

  @override
  List<Object?> get props => [title, notes, dueDate, reminderTime, recurrence, recurrenceConfig];
}

class TodoUpdated extends TodoEvent {
  const TodoUpdated(this.todo);
  final dynamic todo; // typed in bloc to avoid cyclical import noise in test
  @override
  List<Object?> get props => [todo];
}

class TodoDeleted extends TodoEvent {
  const TodoDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class TodoCompletionToggled extends TodoEvent {
  const TodoCompletionToggled(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
