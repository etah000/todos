import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/goal_log.dart';

class GoalLogRepository {
  GoalLogRepository(this._db);
  final AppDatabase _db;
  Database get _raw => _db.raw;

  Future<void> insert(GoalLog l) => _raw.insert(Tables.goalLogs, l.toMap());

  Future<GoalLog?> getById(String id) async {
    final rows = await _raw.query(
      Tables.goalLogs,
      where: '${GoalLogCols.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GoalLog.fromMap(rows.first);
  }

  Future<List<GoalLog>> listByActivity(String activityId) async {
    final rows = await _raw.query(
      Tables.goalLogs,
      where: '${GoalLogCols.goalActivityId} = ?',
      whereArgs: [activityId],
      orderBy: '${GoalLogCols.loggedAt} DESC',
    );
    return rows.map(GoalLog.fromMap).toList();
  }

  Future<List<GoalLog>> listByActivityInRange(
    String activityId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _raw.query(
      Tables.goalLogs,
      where: '${GoalLogCols.goalActivityId} = ? '
          'AND ${GoalLogCols.loggedAt} >= ? '
          'AND ${GoalLogCols.loggedAt} <= ?',
      whereArgs: [
        activityId,
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch,
      ],
      orderBy: '${GoalLogCols.loggedAt} DESC',
    );
    return rows.map(GoalLog.fromMap).toList();
  }

  Future<void> update(GoalLog l) => _raw.update(
        Tables.goalLogs,
        l.toMap(),
        where: '${GoalLogCols.id} = ?',
        whereArgs: [l.id],
      );

  Future<void> delete(String id) => _raw.delete(
        Tables.goalLogs,
        where: '${GoalLogCols.id} = ?',
        whereArgs: [id],
      );
}