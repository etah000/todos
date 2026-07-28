// lib/core/database/migrations.dart
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

class Migrations {
  const Migrations._();

  static const int currentVersion = 4;

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
        ${TodoCols.reminderMode} TEXT NOT NULL DEFAULT 'notification_and_alarm',
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
    batch.execute(
      'CREATE INDEX idx_todo_completions_todo ON ${Tables.todoCompletions}(${TodoCompletionCols.todoId})',
    );

    batch.execute('''
      CREATE TABLE ${Tables.finishedTodos} (
        ${FinishedTodoCols.id} TEXT PRIMARY KEY,
        ${FinishedTodoCols.todoId} TEXT NOT NULL,
        ${FinishedTodoCols.title} TEXT NOT NULL,
        ${FinishedTodoCols.completedAt} INTEGER NOT NULL,
        ${FinishedTodoCols.recurrenceType} TEXT NOT NULL
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_finished_todos_completed_at ON ${Tables.finishedTodos}(${FinishedTodoCols.completedAt})',
    );

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
    batch.execute(
      'CREATE INDEX idx_log_entries_item ON ${Tables.logEntries}(${LogEntryCols.logItemId})',
    );

    batch.execute('''
      CREATE TABLE ${Tables.categories} (
        ${CategoryCols.id} TEXT PRIMARY KEY,
        ${CategoryCols.title} TEXT NOT NULL,
        ${CategoryCols.description} TEXT,
        ${CategoryCols.createdAt} INTEGER NOT NULL,
        ${CategoryCols.updatedAt} INTEGER NOT NULL,
        ${CategoryCols.archived} INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE ${Tables.goalActivities} (
        ${GoalActivityCols.id} TEXT PRIMARY KEY,
        ${GoalActivityCols.categoryId} TEXT NOT NULL,
        ${GoalActivityCols.title} TEXT NOT NULL,
        ${GoalActivityCols.recurrenceType} TEXT NOT NULL,
        ${GoalActivityCols.recurrenceConfig} TEXT,
        ${GoalActivityCols.startDate} INTEGER NOT NULL,
        ${GoalActivityCols.targetValue} REAL NOT NULL DEFAULT 1,
        ${GoalActivityCols.targetUnit} TEXT NOT NULL DEFAULT 'per_period',
        ${GoalActivityCols.metric} TEXT NOT NULL DEFAULT 'boolean',
        ${GoalActivityCols.createdAt} INTEGER NOT NULL,
        FOREIGN KEY (${GoalActivityCols.categoryId}) REFERENCES ${Tables.categories}(id) ON DELETE CASCADE
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_goal_activities_category ON ${Tables.goalActivities}(${GoalActivityCols.categoryId})',
    );

    batch.execute('''
      CREATE TABLE ${Tables.goalLogs} (
        ${GoalLogCols.id} TEXT PRIMARY KEY,
        ${GoalLogCols.goalActivityId} TEXT NOT NULL,
        ${GoalLogCols.value} REAL NOT NULL,
        ${GoalLogCols.notes} TEXT,
        ${GoalLogCols.loggedAt} INTEGER NOT NULL,
        ${GoalLogCols.createdAt} INTEGER NOT NULL,
        FOREIGN KEY (${GoalLogCols.goalActivityId}) REFERENCES ${Tables.goalActivities}(id) ON DELETE CASCADE
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_goal_logs_activity ON ${Tables.goalLogs}(${GoalLogCols.goalActivityId})',
    );

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

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${Tables.finishedTodos} (
          ${FinishedTodoCols.id} TEXT PRIMARY KEY,
          ${FinishedTodoCols.todoId} TEXT NOT NULL,
          ${FinishedTodoCols.title} TEXT NOT NULL,
          ${FinishedTodoCols.completedAt} INTEGER NOT NULL,
          ${FinishedTodoCols.recurrenceType} TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_finished_todos_completed_at ON ${Tables.finishedTodos}(${FinishedTodoCols.completedAt})',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE ${Tables.todos} ADD COLUMN ${TodoCols.reminderMode} TEXT NOT NULL DEFAULT 'notification_and_alarm'",
      );
    }
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS activity_completions');
      await db.execute('DROP TABLE IF EXISTS goal_activities');
      await db.execute('DROP TABLE IF EXISTS goals');

      await db.execute('''
        CREATE TABLE ${Tables.categories} (
          ${CategoryCols.id} TEXT PRIMARY KEY,
          ${CategoryCols.title} TEXT NOT NULL,
          ${CategoryCols.description} TEXT,
          ${CategoryCols.createdAt} INTEGER NOT NULL,
          ${CategoryCols.updatedAt} INTEGER NOT NULL,
          ${CategoryCols.archived} INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE ${Tables.goalActivities} (
          ${GoalActivityCols.id} TEXT PRIMARY KEY,
          ${GoalActivityCols.categoryId} TEXT NOT NULL,
          ${GoalActivityCols.title} TEXT NOT NULL,
          ${GoalActivityCols.recurrenceType} TEXT NOT NULL,
          ${GoalActivityCols.recurrenceConfig} TEXT,
          ${GoalActivityCols.startDate} INTEGER NOT NULL,
          ${GoalActivityCols.targetValue} REAL NOT NULL DEFAULT 1,
          ${GoalActivityCols.targetUnit} TEXT NOT NULL DEFAULT 'per_period',
          ${GoalActivityCols.metric} TEXT NOT NULL DEFAULT 'boolean',
          ${GoalActivityCols.createdAt} INTEGER NOT NULL,
          FOREIGN KEY (${GoalActivityCols.categoryId}) REFERENCES ${Tables.categories}(id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_goal_activities_category ON ${Tables.goalActivities}(${GoalActivityCols.categoryId})',
      );

      await db.execute('''
        CREATE TABLE ${Tables.goalLogs} (
          ${GoalLogCols.id} TEXT PRIMARY KEY,
          ${GoalLogCols.goalActivityId} TEXT NOT NULL,
          ${GoalLogCols.value} REAL NOT NULL,
          ${GoalLogCols.notes} TEXT,
          ${GoalLogCols.loggedAt} INTEGER NOT NULL,
          ${GoalLogCols.createdAt} INTEGER NOT NULL,
          FOREIGN KEY (${GoalLogCols.goalActivityId}) REFERENCES ${Tables.goalActivities}(id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_goal_logs_activity ON ${Tables.goalLogs}(${GoalLogCols.goalActivityId})',
      );
    }
  }
}
