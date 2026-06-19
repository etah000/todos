// lib/core/database/migrations.dart
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

class Migrations {
  const Migrations._();

  static const int currentVersion = 1;

  static Future<void> onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE ${Tables.todos} (
        ${TodoCols.id} TEXT PRIMARY KEY,
        ${TodoCols.title} TEXT NOT NULL,
        ${TodoCols.notes} TEXT,
        ${TodoCols.dueDate} INTEGER,
        ${TodoCols.reminderTime} INTEGER,
        ${TodoCols.recurrenceType} TEXT NOT NULL,
        ${TodoCols.recurrenceConfig} TEXT,
        ${TodoCols.createdAt} INTEGER NOT NULL,
        ${TodoCols.updatedAt} INTEGER NOT NULL,
        ${TodoCols.archived} INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE ${Tables.todoCompletions} (
        ${TodoCompletionCols.id} TEXT PRIMARY KEY,
        ${TodoCompletionCols.todoId} TEXT NOT NULL,
        ${TodoCompletionCols.periodStart} INTEGER NOT NULL,
        ${TodoCompletionCols.periodEnd} INTEGER NOT NULL,
        ${TodoCompletionCols.completedAt} INTEGER NOT NULL,
        ${TodoCompletionCols.notes} TEXT,
        FOREIGN KEY (${TodoCompletionCols.todoId}) REFERENCES ${Tables.todos}(id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_todo_completions_todo ON ${Tables.todoCompletions}(${TodoCompletionCols.todoId})');

    batch.execute('''
      CREATE TABLE ${Tables.logItems} (
        ${LogItemCols.id} TEXT PRIMARY KEY,
        ${LogItemCols.name} TEXT NOT NULL,
        ${LogItemCols.unit} TEXT,
        ${LogItemCols.color} INTEGER,
        ${LogItemCols.createdAt} INTEGER NOT NULL,
        ${LogItemCols.archived} INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE ${Tables.logEntries} (
        ${LogEntryCols.id} TEXT PRIMARY KEY,
        ${LogEntryCols.logItemId} TEXT NOT NULL,
        ${LogEntryCols.value} REAL NOT NULL,
        ${LogEntryCols.notes} TEXT,
        ${LogEntryCols.loggedAt} INTEGER NOT NULL,
        ${LogEntryCols.createdAt} INTEGER NOT NULL,
        FOREIGN KEY (${LogEntryCols.logItemId}) REFERENCES ${Tables.logItems}(id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_log_entries_item ON ${Tables.logEntries}(${LogEntryCols.logItemId})');

    batch.execute('''
      CREATE TABLE ${Tables.goals} (
        ${GoalCols.id} TEXT PRIMARY KEY,
        ${GoalCols.title} TEXT NOT NULL,
        ${GoalCols.description} TEXT,
        ${GoalCols.startDate} INTEGER NOT NULL,
        ${GoalCols.endDate} INTEGER NOT NULL,
        ${GoalCols.createdAt} INTEGER NOT NULL,
        ${GoalCols.updatedAt} INTEGER NOT NULL,
        ${GoalCols.archived} INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE ${Tables.goalActivities} (
        ${GoalActivityCols.id} TEXT PRIMARY KEY,
        ${GoalActivityCols.goalId} TEXT NOT NULL,
        ${GoalActivityCols.title} TEXT NOT NULL,
        ${GoalActivityCols.recurrenceType} TEXT NOT NULL,
        ${GoalActivityCols.recurrenceConfig} TEXT,
        ${GoalActivityCols.createdAt} INTEGER NOT NULL,
        FOREIGN KEY (${GoalActivityCols.goalId}) REFERENCES ${Tables.goals}(id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_goal_activities_goal ON ${Tables.goalActivities}(${GoalActivityCols.goalId})');

    batch.execute('''
      CREATE TABLE ${Tables.activityCompletions} (
        ${ActivityCompletionCols.id} TEXT PRIMARY KEY,
        ${ActivityCompletionCols.activityId} TEXT NOT NULL,
        ${ActivityCompletionCols.periodStart} INTEGER NOT NULL,
        ${ActivityCompletionCols.periodEnd} INTEGER NOT NULL,
        ${ActivityCompletionCols.completedAt} INTEGER NOT NULL,
        ${ActivityCompletionCols.notes} TEXT,
        FOREIGN KEY (${ActivityCompletionCols.activityId}) REFERENCES ${Tables.goalActivities}(id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_activity_completions_activity ON ${Tables.activityCompletions}(${ActivityCompletionCols.activityId})');

    batch.execute('''
      CREATE TABLE ${Tables.countdownEvents} (
        ${CountdownEventCols.id} TEXT PRIMARY KEY,
        ${CountdownEventCols.title} TEXT NOT NULL,
        ${CountdownEventCols.targetDate} INTEGER NOT NULL,
        ${CountdownEventCols.notes} TEXT,
        ${CountdownEventCols.createdAt} INTEGER NOT NULL,
        ${CountdownEventCols.archived} INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await batch.commit(noResult: true);
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Reserved for future migrations.
  }
}
