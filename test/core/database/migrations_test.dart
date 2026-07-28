import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/core/database/migrations.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  test('onUpgrade v3→v4 creates new tables and drops the old', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (d, _) async {
          await d.execute(
            'CREATE TABLE goals (id TEXT PRIMARY KEY, title TEXT, start_date INTEGER, end_date INTEGER, created_at INTEGER, updated_at INTEGER, archived INTEGER)',
          );
          await d.execute(
            'CREATE TABLE goal_activities (id TEXT PRIMARY KEY, goal_id TEXT, title TEXT, recurrence_type TEXT, created_at INTEGER)',
          );
          await d.execute(
            'CREATE TABLE activity_completions (id TEXT PRIMARY KEY, activity_id TEXT, period_start INTEGER, period_end INTEGER, completed_at INTEGER)',
          );
        },
        onUpgrade: Migrations.onUpgrade,
      ),
    );

    await db.setVersion(4);
    await Migrations.onUpgrade(db, 3, 4);

    final names = (await db.query('sqlite_master', columns: ['name']))
        .map((r) => r['name'] as String)
        .toSet();
    expect(names.contains('categories'), isTrue);
    expect(names.contains('goal_activities'), isTrue);
    expect(names.contains('goal_logs'), isTrue);
    expect(names.contains('activity_completions'), isFalse);
    expect(names.contains('goals'), isFalse);
    await db.close();
  });

  test('currentVersion is 4', () {
    expect(Migrations.currentVersion, 4);
  });
}