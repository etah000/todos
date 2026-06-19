// lib/features/todos/data/todo_completion_repository.dart
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/todo_completion.dart';

class TodoCompletionRepository {
  TodoCompletionRepository(this._db);
  final AppDatabase _db;

  Database get _raw => _db.raw;

  Future<void> insert(TodoCompletion c) async {
    await _raw.insert(Tables.todoCompletions, c.toMap());
  }

  Future<List<TodoCompletion>> listByTodo(String todoId) async {
    final rows = await _raw.query(
      Tables.todoCompletions,
      where: '${TodoCompletionCols.todoId} = ?',
      whereArgs: [todoId],
      orderBy: '${TodoCompletionCols.completedAt} DESC',
    );
    return rows.map(TodoCompletion.fromMap).toList();
  }

  Future<TodoCompletion?> findByTodoInPeriod(
    String todoId, {
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final rows = await _raw.query(
      Tables.todoCompletions,
      where: '${TodoCompletionCols.todoId} = ? '
          'AND ${TodoCompletionCols.periodStart} <= ? '
          'AND ${TodoCompletionCols.periodEnd} >= ?',
      whereArgs: [
        todoId,
        periodEnd.millisecondsSinceEpoch,
        periodStart.millisecondsSinceEpoch,
      ],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TodoCompletion.fromMap(rows.first);
  }
}
