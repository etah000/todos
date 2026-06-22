// lib/features/goals/data/activity_completion_repository.dart
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/activity_completion.dart';

class ActivityCompletionRepository {
  ActivityCompletionRepository(this._db);
  final AppDatabase _db;
  Database get _raw => _db.raw;

  Future<void> insert(ActivityCompletion c) => _raw.insert(Tables.activityCompletions, c.toMap());

  Future<ActivityCompletion?> findByActivityInPeriod(
    String activityId, {
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final rows = await _raw.query(
      Tables.activityCompletions,
      where: '${ActivityCompletionCols.activityId} = ? '
          'AND ${ActivityCompletionCols.periodStart} <= ? '
          'AND ${ActivityCompletionCols.periodEnd} >= ?',
      whereArgs: [activityId, periodEnd.millisecondsSinceEpoch, periodStart.millisecondsSinceEpoch],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ActivityCompletion.fromMap(rows.first);
  }

  Future<List<ActivityCompletion>> listByActivity(String activityId) async {
    final rows = await _raw.query(
      Tables.activityCompletions,
      where: '${ActivityCompletionCols.activityId} = ?',
      whereArgs: [activityId],
      orderBy: '${ActivityCompletionCols.completedAt} DESC',
    );
    return rows.map(ActivityCompletion.fromMap).toList();
  }
}