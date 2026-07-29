import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todos/features/goals/data/category_repository.dart';
import 'package:todos/features/goals/data/goal_activity_repository.dart';
import 'package:todos/features/goals/data/goal_log_repository.dart';
import 'package:todos/features/goals/domain/category.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_log.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:todos/features/goals/presentation/bloc/goal_event.dart';
import 'package:todos/features/goals/presentation/bloc/goal_state.dart';
import 'package:todos/features/todos/domain/recurrence.dart';
import 'package:uuid/uuid.dart';

class _MockCategories extends Mock implements CategoryRepository {}
class _MockActivities extends Mock implements GoalActivityRepository {}
class _MockLogs extends Mock implements GoalLogRepository {}

void main() {
  late _MockCategories categories;
  late _MockActivities activities;
  late _MockLogs logs;
  final fixedNow = DateTime(2026, 7, 5);

  setUpAll(() {
    registerFallbackValue(GoalLog(
      id: 'x', goalActivityId: 'x', value: 0,
      loggedAt: fixedNow, createdAt: fixedNow,
    ));
    registerFallbackValue(Category(
      id: 'x', title: 'x',
      createdAt: fixedNow, updatedAt: fixedNow, archived: false,
    ));
  });

  setUp(() {
    categories = _MockCategories();
    activities = _MockActivities();
    logs = _MockLogs();
    when(() => categories.getAll(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) async => [
              Category(id: 'c1', title: 'Health',
                createdAt: DateTime(2026, 1, 1),
                updatedAt: DateTime(2026, 1, 1),
                archived: false),
            ]);
    when(() => activities.listByCategory('c1')).thenAnswer((_) async => [
          GoalActivity(
            id: 'a1', categoryId: 'c1', title: 'pushup',
            recurrence: Recurrence.daily,
            startDate: DateTime(2026, 7, 1),
            targetValue: 15,
            targetUnit: GoalTargetUnit.perDay,
            metric: ActivityMetric.count,
            createdAt: DateTime(2026, 7, 1),
          ),
        ]);
    when(() => logs.listByActivity('a1')).thenAnswer((_) async => []);
  });

  GoalBloc build() => GoalBloc(
        categoryRepo: categories,
        activityRepo: activities,
        logRepo: logs,
        uuid: const Uuid(),
        now: () => fixedNow,
      );

  blocTest<GoalBloc, GoalState>(
    'SubscriptionRequested emits loaded with categories and precomputed snapshots',
    build: build,
    act: (b) => b.add(const GoalsSubscriptionRequested()),
    expect: () => [
      const GoalLoading(),
      predicate<GoalState>((s) =>
          s is GoalsLoaded &&
          s.categories.length == 1 &&
          s.activitiesByCategoryId['c1']!.length == 1 &&
          s.activitiesByCategoryId['c1']!.first.progressSnapshot != null),
    ],
  );

  blocTest<GoalBloc, GoalState>(
    'CategoryCreated inserts and reloads',
    build: () {
      when(() => categories.insert(any())).thenAnswer((_) async {});
      return build();
    },
    act: (b) => b.add(const CategoryCreated(title: 'Wealth')),
    verify: (_) => verify(() => categories.insert(any())).called(1),
  );

  blocTest<GoalBloc, GoalState>(
    'GoalLogBooleanToggled inserts one log row for an empty period',
    build: () {
      when(() => logs.listByActivity('a1')).thenAnswer((_) async => []);
      when(() => logs.listByActivityInRange('a1',
          from: any(named: 'from'), to: any(named: 'to')))
          .thenAnswer((_) async => []);
      when(() => logs.insert(any())).thenAnswer((_) async {});
      return build();
    },
    act: (b) => b.add(GoalLogBooleanToggled(
      goalActivityId: 'a1',
      periodStart: DateTime(2026, 7, 1),
      periodEnd: DateTime(2026, 7, 1, 23, 59, 59, 999),
    )),
    verify: (_) => verify(() => logs.insert(any())).called(1),
  );

  blocTest<GoalBloc, GoalState>(
    'GoalLogCountAdded inserts a log with the delta',
    build: () {
      when(() => logs.insert(any())).thenAnswer((_) async {});
      return build();
    },
    act: (b) => b.add(const GoalLogCountAdded(goalActivityId: 'a1', delta: 5)),
    verify: (_) {
      final captured = verify(() => logs.insert(captureAny())).captured.single as GoalLog;
      expect(captured.value, 5);
    },
  );
}