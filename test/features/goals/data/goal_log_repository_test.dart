import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/goals/data/goal_log_repository.dart';
import 'package:todos/features/goals/domain/goal_log.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase db;
  late GoalLogRepository repo;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    repo = GoalLogRepository(db);
    // Insert parent rows directly via raw SQL to satisfy the FK constraint
    // on goal_logs.goal_activity_id without coupling this test to the
    // not-yet-extended GoalActivity model (Task 5).
    await db.raw.insert('categories', {
      'id': 'c1', 'title': 'Health', 'description': null,
      'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      'updated_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      'archived': 0,
    });
    await db.raw.insert('goal_activities', {
      'id': 'a1', 'category_id': 'c1', 'title': 'pushup',
      'recurrence_type': 'daily', 'recurrence_config': null,
      'start_date': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      'target_value': 1, 'target_unit': 'per_day',
      'metric': 'boolean',
      'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
    });
    await db.raw.insert('goal_activities', {
      'id': 'a2', 'category_id': 'c1', 'title': 'meditate',
      'recurrence_type': 'daily', 'recurrence_config': null,
      'start_date': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      'target_value': 1, 'target_unit': 'per_day',
      'metric': 'boolean',
      'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
    });
  });
  tearDown(() async => db.close());

  GoalLog makeLog(String id, String activityId, {DateTime? loggedAt, double value = 1.0}) =>
      GoalLog(
        id: id, goalActivityId: activityId, value: value,
        loggedAt: loggedAt ?? DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );

  test('insert + getById round-trip', () async {
    await repo.insert(makeLog('l1', 'a1'));
    expect((await repo.getById('l1'))!.id, 'l1');
  });

  test('listByActivity returns logs in descending loggedAt order', () async {
    await repo.insert(makeLog('l1', 'a1', loggedAt: DateTime(2026, 1, 1)));
    await repo.insert(makeLog('l2', 'a1', loggedAt: DateTime(2026, 1, 3)));
    await repo.insert(makeLog('l3', 'a2', loggedAt: DateTime(2026, 1, 2)));
    final logs = await repo.listByActivity('a1');
    expect(logs.map((l) => l.id), ['l2', 'l1']);
  });

  test('listByActivityInRange filters by loggedAt', () async {
    await repo.insert(makeLog('l1', 'a1', loggedAt: DateTime(2026, 1, 1)));
    await repo.insert(makeLog('l2', 'a1', loggedAt: DateTime(2026, 1, 10)));
    final logs = await repo.listByActivityInRange(
      'a1', from: DateTime(2026, 1, 5), to: DateTime(2026, 1, 31));
    expect(logs.map((l) => l.id), ['l2']);
  });

  test('update persists changes', () async {
    await repo.insert(makeLog('l1', 'a1'));
    await repo.update(makeLog('l1', 'a1').copyWith(value: 5.0));
    expect((await repo.getById('l1'))!.value, 5.0);
  });

  test('delete removes the row', () async {
    await repo.insert(makeLog('l1', 'a1'));
    await repo.delete('l1');
    expect(await repo.getById('l1'), isNull);
  });
}