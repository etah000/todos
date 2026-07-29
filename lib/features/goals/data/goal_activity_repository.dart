import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/goal_activity.dart';

class GoalActivityRepository {
  GoalActivityRepository(this._db);
  final AppDatabase _db;
  Database get _raw => _db.raw;

  Future<void> insert(GoalActivity a) => _raw.insert(Tables.goalActivities, a.toMap());

  Future<List<GoalActivity>> listByCategory(String categoryId) async {
    final rows = await _raw.query(
      Tables.goalActivities,
      where: '${GoalActivityCols.categoryId} = ?',
      whereArgs: [categoryId],
      orderBy: '${GoalActivityCols.createdAt} ASC',
    );
    return rows.map(GoalActivity.fromMap).toList();
  }

  Future<void> delete(String id) => _raw.delete(
        Tables.goalActivities,
        where: '${GoalActivityCols.id} = ?',
        whereArgs: [id],
      );

  Future<void> update(GoalActivity a) => _raw.update(
        Tables.goalActivities,
        a.toMap(),
        where: '${GoalActivityCols.id} = ?',
        whereArgs: [a.id],
      );

  Future<GoalActivity?> getById(String id) async {
    final rows = await _raw.query(
      Tables.goalActivities,
      where: '${GoalActivityCols.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GoalActivity.fromMap(rows.first);
  }
}
