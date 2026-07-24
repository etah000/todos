// lib/features/todos/presentation/bloc/todo_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/finished_todo.dart';
import '../../domain/todo.dart';
import '../../domain/todo_completion.dart';

abstract class TodoState extends Equatable {
  const TodoState();
  @override
  List<Object?> get props => [];
}

class TodosInitial extends TodoState {
  const TodosInitial();
}

class TodosLoading extends TodoState {
  const TodosLoading();
}

class TodosLoaded extends TodoState {
  const TodosLoaded({
    required this.items,
    this.completionsByTodoId = const {},
    this.history = const [],
  });
  final List<Todo> items;
  final Map<String, TodoCompletion> completionsByTodoId;
  final List<FinishedTodo> history;

  TodosLoaded copyWith({
    List<Todo>? items,
    Map<String, TodoCompletion>? completionsByTodoId,
    List<FinishedTodo>? history,
  }) =>
      TodosLoaded(
        items: items ?? this.items,
        completionsByTodoId: completionsByTodoId ?? this.completionsByTodoId,
        history: history ?? this.history,
      );

  @override
  List<Object?> get props => [items, completionsByTodoId, history];
}

class TodosError extends TodoState {
  const TodosError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
