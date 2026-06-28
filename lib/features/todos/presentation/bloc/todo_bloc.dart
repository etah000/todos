// lib/features/todos/presentation/bloc/todo_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/todo_completion_repository.dart';
import '../../data/todo_repository.dart';
import '../../domain/recurrence.dart';
import '../../domain/todo.dart';
import '../../domain/todo_completion.dart';
import 'notification_scheduler.dart';
import 'todo_event.dart';
import 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc({
    required TodoRepository todoRepo,
    required TodoCompletionRepository completionRepo,
    required Uuid uuid,
    required NotificationScheduler notifications,
    DateTime Function()? now,
  })  : _todos = todoRepo,
        _completions = completionRepo,
        _uuid = uuid,
        _notifications = notifications,
        _now = now ?? DateTime.now,
        super(const TodosInitial()) {
    on<TodosSubscriptionRequested>(_onSubscribe);
    on<TodoCreated>(_onCreated);
    on<TodoUpdated>(_onUpdated);
    on<TodoDeleted>(_onDeleted);
    on<TodoCompletionToggled>(_onToggled);
  }

  final TodoRepository _todos;
  final TodoCompletionRepository _completions;
  final Uuid _uuid;
  final NotificationScheduler _notifications;
  final DateTime Function() _now;

  Future<void> _onSubscribe(TodosSubscriptionRequested e, Emitter<TodoState> emit) async {
    emit(const TodosLoading());
    try {
      final items = await _todos.getAll();
      final at = _now();
      final completions = <String, TodoCompletion>{};
      for (final t in items) {
        final (start, end) = t.recurrence.periodFor(t.dueDate ?? at, at: at);
        final c = await _completions.findByTodoInPeriod(t.id, periodStart: start, periodEnd: end);
        if (c != null) completions[t.id] = c;
      }
      emit(TodosLoaded(items: items, completionsByTodoId: completions));
    } catch (err) {
      emit(TodosError(err.toString()));
    }
  }

  Future<void> _onCreated(TodoCreated e, Emitter<TodoState> emit) async {
    final at = _now();
    final todo = Todo(
      id: _uuid.v4(),
      title: e.title,
      notes: e.notes,
      dueDate: e.dueDate,
      reminderTime: e.reminderTime,
      recurrence: e.recurrence,
      recurrenceConfig: e.recurrenceConfig,
      createdAt: at,
      updatedAt: at,
      archived: false,
    );
    await _todos.insert(todo);
    await _maybeScheduleReminder(todo);
    add(const TodosSubscriptionRequested());
  }

  Future<void> _onUpdated(TodoUpdated e, Emitter<TodoState> emit) async {
    final updated = (e.todo as Todo).copyWith(updatedAt: _now());
    await _todos.update(updated);
    await _notifications.cancel(updated.id);
    await _maybeScheduleReminder(updated);
    add(const TodosSubscriptionRequested());
  }

  Future<void> _onDeleted(TodoDeleted e, Emitter<TodoState> emit) async {
    await _todos.delete(e.id);
    await _notifications.cancel(e.id);
    add(const TodosSubscriptionRequested());
  }

  /// Schedules the reminder only when [Recurrence.nextReminderAfter] returns
  /// a non-null value. A past one-time reminder is not re-armed; a past
  /// recurring reminder is always scheduled (the OS picks the next match
  /// via [DateTimeComponents]).
  Future<void> _maybeScheduleReminder(Todo todo) async {
    final r = todo.reminderTime;
    if (r == null) return;
    if (todo.recurrence.nextReminderAfter(r, now: _now()) == null) return;
    await _notifications.schedule(
      todo.id,
      todo.title,
      r,
      recurrence: todo.recurrence,
    );
  }

  Future<void> _onToggled(TodoCompletionToggled e, Emitter<TodoState> emit) async {
    final todo = await _todos.getById(e.id);
    if (todo == null) return;
    final at = _now();
    final (start, end) = todo.recurrence.periodFor(todo.dueDate ?? at, at: at);
    final existing = await _completions.findByTodoInPeriod(
      todo.id,
      periodStart: start,
      periodEnd: end,
    );
    if (existing == null) {
      final c = TodoCompletion(
        id: _uuid.v4(),
        todoId: todo.id,
        periodStart: start,
        periodEnd: end,
        completedAt: at,
      );
      await _completions.insert(c);
    }
    add(const TodosSubscriptionRequested());
  }
}
