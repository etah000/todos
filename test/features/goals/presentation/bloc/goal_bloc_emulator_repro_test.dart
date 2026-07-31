import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/goals/data/category_repository.dart';
import 'package:todos/features/goals/data/goal_activity_repository.dart';
import 'package:todos/features/goals/data/goal_log_repository.dart';
import 'package:todos/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:todos/features/goals/presentation/bloc/goal_event.dart';
import 'package:todos/features/goals/presentation/bloc/goal_state.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase db;
  late CategoryRepository categories;
  late GoalActivityRepository activities;
  late GoalLogRepository logs;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    categories = CategoryRepository(db);
    activities = GoalActivityRepository(db);
    logs = GoalLogRepository(db);
  });
  tearDown(() async => db.close());

  GoalBloc build() => GoalBloc(
        categoryRepo: categories,
        activityRepo: activities,
        logRepo: logs,
        uuid: const Uuid(),
      );

  test('CategoryCreated persists the category to the database', () async {
    final bloc = build();
    bloc.add(const GoalsSubscriptionRequested());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    bloc.add(const CategoryCreated(title: 'Health'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final all = await categories.getAll();
    expect(all.length, 1);
    expect(all.first.title, 'Health');
  });

  test('CategoryCreated triggers GoalsLoaded with the new category', () async {
    final bloc = build();
    final emissions = <GoalState>[];
    final sub = bloc.stream.listen(emissions.add);

    bloc.add(const GoalsSubscriptionRequested());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    bloc.add(const CategoryCreated(title: 'Wealth'));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final loaded = emissions.whereType<GoalsLoaded>().toList();
    expect(loaded.length, greaterThanOrEqualTo(2));
    expect(loaded.last.categories.length, 1);
    expect(loaded.last.categories.first.title, 'Wealth');

    await sub.cancel();
  });
}