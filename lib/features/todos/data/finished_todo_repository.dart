// lib/features/todos/data/finished_todo_repository.dart
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/finished_todo.dart';

class FinishedTodoRepository {
  FinishedTodoRepository(this._db);
  final AppDatabase _db;
  Database get _raw => _db.raw;

  Future<void> insert(FinishedTodo f) =>
      _raw.insert(Tables.finishedTodos, f.toMap());

  /// All history rows whose `completedAt` is within the last [within].
  Future<List<FinishedTodo>> listSince(DateTime since) async {
    final rows = await _raw.query(
      Tables.finishedTodos,
      where: '${FinishedTodoCols.completedAt} >= ?',
      whereArgs: [since.millisecondsSinceEpoch],
      orderBy: '${FinishedTodoCols.completedAt} DESC',
    );
    return rows.map(FinishedTodo.fromMap).toList();
  }

  /// Delete rows older than [before] — used to enforce the 7-day retention.
  Future<int> deleteBefore(DateTime before) => _raw.delete(
        Tables.finishedTodos,
        where: '${FinishedTodoCols.completedAt} < ?',
        whereArgs: [before.millisecondsSinceEpoch],
      );
}
