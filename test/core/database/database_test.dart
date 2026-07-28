import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/core/database/schema.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('AppDatabase', () {
    late AppDatabase db;

    setUp(() async {
      db = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('creates every table', () async {
      final tables = await db.raw.query(
        'sqlite_master',
        columns: ['name'],
        where: 'type = ?',
        whereArgs: ['table'],
      );
      final names = tables.map((r) => r['name'] as String).toSet();
      expect(
        names,
        containsAll([
          Tables.todos,
          Tables.todoCompletions,
          Tables.logItems,
          Tables.logEntries,
          Tables.goals,
          Tables.goalActivities,
          Tables.activityCompletions,
          Tables.countdownEvents,
        ]),
      );
    });

    test('creates todos with reminder mode default column', () async {
      final columns =
          await db.raw.rawQuery('PRAGMA table_info(${Tables.todos})');
      final reminderMode = columns.singleWhere(
        (row) => row['name'] == TodoCols.reminderMode,
      );
      expect(reminderMode['dflt_value'], "'notification_and_alarm'");
    });

    test('enables foreign keys (cascading delete)', () async {
      // Insert a todo then a completion, delete the todo, expect the completion gone.
      const todoId = 't1';
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.raw.insert(Tables.todos, {
        'id': todoId,
        'title': 'rent',
        'recurrence_type': 'monthly',
        'created_at': now,
        'updated_at': now,
        'archived': 0,
      });
      await db.raw.insert(Tables.todoCompletions, {
        'id': 'c1',
        'todo_id': todoId,
        'period_start': now,
        'period_end': now,
        'completed_at': now,
      });
      await db.raw.delete(Tables.todos, where: 'id = ?', whereArgs: [todoId]);
      final remaining = await db.raw.query(
        Tables.todoCompletions,
        where: 'todo_id = ?',
        whereArgs: [todoId],
      );
      expect(remaining, isEmpty);
    });
  });
}
