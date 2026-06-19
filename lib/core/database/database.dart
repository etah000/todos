// lib/core/database/database.dart
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;
  Database get raw => _db;

  static Future<AppDatabase> open({required String path, DatabaseFactory? factory}) async {
    final f = factory ?? databaseFactory;
    final db = await f.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: Migrations.currentVersion,
        onConfigure: (d) async {
          await d.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: Migrations.onCreate,
        onUpgrade: Migrations.onUpgrade,
      ),
    );
    return AppDatabase._(db);
  }

  Future<void> close() => _db.close();
}
