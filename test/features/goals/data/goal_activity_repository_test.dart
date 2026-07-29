import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/goals/data/category_repository.dart';
import 'package:todos/features/goals/data/goal_activity_repository.dart';
import 'package:todos/features/goals/domain/category.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/todos/domain/recurrence.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase db;
  late GoalActivityRepository repo;
  late CategoryRepository categories;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    repo = GoalActivityRepository(db);
    categories = CategoryRepository(db);
    await categories.insert(Category(
      id: 'c1', title: 'Health',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      archived: false,
    ));
  });
  tearDown(() async => db.close());

  GoalActivity makeActivity(String id, String categoryId, {String title = 'pushup'}) =>
      GoalActivity(
        id: id, categoryId: categoryId, title: title,
        recurrence: Recurrence.daily,
        startDate: DateTime(2026, 1, 1),
        targetValue: 15,
        targetUnit: GoalTargetUnit.perDay,
        metric: ActivityMetric.count,
        createdAt: DateTime(2026, 1, 1),
      );

  test('insert + listByCategory round-trip', () async {
    await repo.insert(makeActivity('a1', 'c1'));
    await repo.insert(makeActivity('a2', 'c1', title: 'meditate'));
    final list = await repo.listByCategory('c1');
    expect(list.map((a) => a.id), ['a1', 'a2']);
  });

  test('delete cascades to goal_logs', () async {
    await repo.insert(makeActivity('a1', 'c1'));
    await db.raw.insert('goal_logs', {
      'id': 'l1', 'goal_activity_id': 'a1', 'value': 1.0,
      'logged_at': 1000, 'created_at': 1000,
    });
    await repo.delete('a1');
    final logs = await db.raw.query('goal_logs', where: 'id = ?', whereArgs: ['l1']);
    expect(logs, isEmpty);
  });

  test('delete cascades to activities when category is deleted', () async {
    await repo.insert(makeActivity('a1', 'c1'));
    await categories.delete('c1');
    final list = await repo.listByCategory('c1');
    expect(list, isEmpty);
  });

  test('update persists new target_value and target_unit', () async {
    await repo.insert(makeActivity('a1', 'c1'));
    final updated = (await repo.getById('a1'))!.copyWith(
      targetValue: 90,
      targetUnit: GoalTargetUnit.perWeek,
    );
    await repo.update(updated);
    final reloaded = (await repo.getById('a1'))!;
    expect(reloaded.targetValue, 90);
    expect(reloaded.targetUnit, GoalTargetUnit.perWeek);
  });
}
