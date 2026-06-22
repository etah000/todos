// lib/features/goals/data/goal_repository.dart
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/goal.dart';

class GoalRepository {
  GoalRepository(this._db);
  final AppDatabase _db;
  Database get _raw => _db.raw;

  Future<void> insert(Goal g) => _raw.insert(Tables.goals, g.toMap());
  Future<Goal?> getById(String id) async {
    final rows = await _raw.query(Tables.goals, where: '${GoalCols.id} = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Goal.fromMap(rows.first);
  }
  Future<List<Goal>> getAll() async {
    final rows = await _raw.query(
      Tables.goals,
      orderBy: '${GoalCols.archived} ASC, ${GoalCols.createdAt} DESC',
    );
    return rows.map(Goal.fromMap).toList();
  }
  Future<void> update(Goal g) => _raw.update(Tables.goals, g.toMap(), where: '${GoalCols.id} = ?', whereArgs: [g.id]);
  Future<void> delete(String id) => _raw.delete(Tables.goals, where: '${GoalCols.id} = ?', whereArgs: [id]);
}