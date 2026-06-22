// lib/features/logs/data/log_item_repository.dart
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/log_item.dart';

class LogItemRepository {
  LogItemRepository(this._db);
  final AppDatabase _db;
  Database get _raw => _db.raw;

  Future<void> insert(LogItem item) => _raw.insert(Tables.logItems, item.toMap());

  Future<List<LogItem>> getAll({bool includeArchived = false}) async {
    final rows = await _raw.query(
      Tables.logItems,
      where: includeArchived ? null : '${LogItemCols.archived} = 0',
      orderBy: '${LogItemCols.createdAt} ASC',
    );
    return rows.map(LogItem.fromMap).toList();
  }

  Future<LogItem?> getById(String id) async {
    final rows = await _raw.query(Tables.logItems, where: '${LogItemCols.id} = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return LogItem.fromMap(rows.first);
  }

  Future<void> update(LogItem item) => _raw.update(
        Tables.logItems,
        item.toMap(),
        where: '${LogItemCols.id} = ?',
        whereArgs: [item.id],
      );

  Future<void> delete(String id) => _raw.delete(Tables.logItems, where: '${LogItemCols.id} = ?', whereArgs: [id]);
}