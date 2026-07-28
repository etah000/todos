// lib/features/logs/data/log_entry_repository.dart
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/log_entry.dart';

class LogEntryRepository {
  LogEntryRepository(this._db);
  final AppDatabase _db;
  Database get _raw => _db.raw;

  Future<void> insert(LogEntry e) => _raw.insert(Tables.logEntries, e.toMap());

  Future<List<LogEntry>> listByItemInRange(
    String itemId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _raw.query(
      Tables.logEntries,
      where: '${LogEntryCols.logItemId} = ? '
          'AND ${LogEntryCols.loggedAt} >= ? '
          'AND ${LogEntryCols.loggedAt} <= ?',
      whereArgs: [
        itemId,
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch,
      ],
      orderBy: '${LogEntryCols.loggedAt} DESC',
    );
    return rows.map(LogEntry.fromMap).toList();
  }

  Future<void> delete(String id) => _raw.delete(
        Tables.logEntries,
        where: '${LogEntryCols.id} = ?',
        whereArgs: [id],
      );
}
