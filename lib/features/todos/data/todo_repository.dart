// lib/features/todos/data/todo_repository.dart
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/todo.dart';

class TodoRepository {
  TodoRepository(this._db);
  final AppDatabase _db;

  Database get _raw => _db.raw;

  Future<void> insert(Todo t) async {
    await _raw.insert(Tables.todos, t.toMap());
  }

  Future<Todo?> getById(String id) async {
    final rows = await _raw.query(Tables.todos, where: '${TodoCols.id} = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Todo.fromMap(rows.first);
  }

  Future<List<Todo>> getAll() async {
    final rows = await _raw.query(
      Tables.todos,
      orderBy: '${TodoCols.archived} ASC, ${TodoCols.createdAt} DESC',
    );
    return rows.map(Todo.fromMap).toList();
  }

  Future<void> update(Todo t) async {
    await _raw.update(Tables.todos, t.toMap(), where: '${TodoCols.id} = ?', whereArgs: [t.id]);
  }

  Future<void> delete(String id) async {
    await _raw.delete(Tables.todos, where: '${TodoCols.id} = ?', whereArgs: [id]);
  }
}
