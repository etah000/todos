// lib/features/goals/data/goal_activity_repository.dart
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/goal_activity.dart';

class GoalActivityRepository {
  GoalActivityRepository(this._db);
  final AppDatabase _db;
  Database get _raw => _db.raw;

  Future<void> insert(GoalActivity a) => _raw.insert(Tables.goalActivities, a.toMap());

  Future<List<GoalActivity>> listByGoal(String goalId) async {
    final rows = await _raw.query(
      Tables.goalActivities,
      where: '${GoalActivityCols.goalId} = ?',
      whereArgs: [goalId],
      orderBy: '${GoalActivityCols.createdAt} ASC',
    );
    return rows.map(GoalActivity.fromMap).toList();
  }

  Future<void> delete(String id) => _raw.delete(
        Tables.goalActivities,
        where: '${GoalActivityCols.id} = ?',
        whereArgs: [id],
      );
}