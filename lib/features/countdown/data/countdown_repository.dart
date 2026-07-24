// lib/features/countdown/data/countdown_repository.dart
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/countdown_event.dart';

class CountdownRepository {
  CountdownRepository(this._db);
  final AppDatabase _db;
  Database get _raw => _db.raw;

  Future<void> insert(CountdownEvent e) => _raw.insert(Tables.countdownEvents, e.toMap());

  Future<List<CountdownEvent>> getAll() async {
    final rows = await _raw.query(
      Tables.countdownEvents,
      where: '${CountdownEventCols.archived} = 0',
      orderBy: '${CountdownEventCols.targetDate} ASC',
    );
    return rows.map(CountdownEvent.fromMap).toList();
  }

  Future<void> delete(String id) => _raw.delete(
        Tables.countdownEvents,
        where: '${CountdownEventCols.id} = ?',
        whereArgs: [id],
      );

  Future<void> update(CountdownEvent e) => _raw.update(
        Tables.countdownEvents,
        e.toMap(),
        where: '${CountdownEventCols.id} = ?',
        whereArgs: [e.id],
      );
}