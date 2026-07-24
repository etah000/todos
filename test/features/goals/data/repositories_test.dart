// test/features/goals/data/repositories_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/goals/data/activity_completion_repository.dart';
import 'package:todos/features/goals/data/goal_activity_repository.dart';
import 'package:todos/features/goals/data/goal_repository.dart';
import 'package:todos/features/goals/domain/activity_completion.dart';
import 'package:todos/features/goals/domain/goal.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/todos/domain/recurrence.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase db;
  late GoalRepository goals;
  late GoalActivityRepository activities;
  late ActivityCompletionRepository completions;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    goals = GoalRepository(db);
    activities = GoalActivityRepository(db);
    completions = ActivityCompletionRepository(db);
  });
  tearDown(() async => db.close());

  Goal makeGoal({String id = 'g1'}) {
    final now = DateTime.now();
    return Goal(
      id: id, title: 'Get fit',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 8, 31),
      createdAt: now, updatedAt: now, archived: false,
    );
  }

  GoalActivity makeActivity({String id = 'a1', String goalId = 'g1'}) {
    return GoalActivity(
      id: id, goalId: goalId, title: 'workout',
      recurrence: Recurrence.weekly, createdAt: DateTime(2026, 6, 1),
    );
  }

  group('GoalRepository', () {
    test('insert + getById + getAll', () async {
      await goals.insert(makeGoal());
      await goals.insert(makeGoal(id: 'g2'));
      final all = await goals.getAll();
      expect(all.length, 2);
      final g = await goals.getById('g1');
      expect(g, isNotNull);
    });
  });

  group('GoalActivityRepository', () {
    test('listByGoal cascades on goal delete', () async {
      await goals.insert(makeGoal());
      await activities.insert(makeActivity());
      final list = await activities.listByGoal('g1');
      expect(list, hasLength(1));
      await goals.delete('g1');
      final after = await activities.listByGoal('g1');
      expect(after, isEmpty);
    });
  });

  group('ActivityCompletionRepository', () {
    test('findByActivityInPeriod returns the completion', () async {
      await goals.insert(makeGoal());
      await activities.insert(makeActivity());
      final c = ActivityCompletion(
        id: 'c1', activityId: 'a1',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 30, 23, 59, 59, 999),
        completedAt: DateTime(2026, 6, 10),
      );
      await completions.insert(c);
      final got = await completions.findByActivityInPeriod(
        'a1',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 30, 23, 59, 59, 999),
      );
      expect(got, c);
    });

    test('listByActivitiesInRange returns only completions in [from, to)',
        () async {
      await goals.insert(makeGoal());
      await activities.insert(makeActivity());
      await activities.insert(makeActivity(id: 'a2'));
      await completions.insert(ActivityCompletion(
        id: 'c1', activityId: 'a1',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 7, 23, 59, 59, 999),
        completedAt: DateTime(2026, 6, 1, 9),
      ));
      await completions.insert(ActivityCompletion(
        id: 'c2', activityId: 'a2',
        periodStart: DateTime(2026, 6, 8),
        periodEnd: DateTime(2026, 6, 14, 23, 59, 59, 999),
        completedAt: DateTime(2026, 6, 8, 9),
      ));
      await completions.insert(ActivityCompletion(
        id: 'c3', activityId: 'a1',
        periodStart: DateTime(2026, 6, 15),
        periodEnd: DateTime(2026, 6, 21, 23, 59, 59, 999),
        completedAt: DateTime(2026, 6, 15, 9),
      ));
      // query c1 + c2 only (week 1)
      final week1 = await completions.listByActivitiesInRange(
        ['a1', 'a2'],
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 6, 8),
      );
      expect(week1.map((c) => c.id), ['c1']);
      // empty ids
      final none = await completions.listByActivitiesInRange(
        const [],
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 6, 30),
      );
      expect(none, isEmpty);
    });
  });
}