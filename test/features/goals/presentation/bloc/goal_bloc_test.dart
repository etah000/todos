// test/features/goals/presentation/bloc/goal_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todos/features/goals/data/activity_completion_repository.dart';
import 'package:todos/features/goals/data/goal_activity_repository.dart';
import 'package:todos/features/goals/data/goal_repository.dart';
import 'package:todos/features/goals/domain/activity_completion.dart';
import 'package:todos/features/goals/domain/goal.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:todos/features/goals/presentation/bloc/goal_event.dart';
import 'package:todos/features/goals/presentation/bloc/goal_state.dart';
import 'package:todos/features/todos/domain/recurrence.dart';
import 'package:uuid/uuid.dart';

class _MockGoals extends Mock implements GoalRepository {}

class _MockActivities extends Mock implements GoalActivityRepository {}

class _MockCompletions extends Mock implements ActivityCompletionRepository {}

void main() {
  late _MockGoals goals;
  late _MockActivities activities;
  late _MockCompletions completions;

  Goal makeGoal({String id = 'g1'}) => Goal(
        id: id,
        title: 'A',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 8, 31),
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
        archived: false,
      );

  GoalActivity makeActivity({String id = 'a1'}) => GoalActivity(
        id: id,
        goalId: 'g1',
        title: 'workout',
        recurrence: Recurrence.weekly,
        createdAt: DateTime(2026, 6, 1),
      );

  setUpAll(() {
    registerFallbackValue(ActivityCompletion(
      id: 'x',
      activityId: 'x',
      periodStart: DateTime(2026, 1, 1),
      periodEnd: DateTime(2026, 1, 31, 23, 59, 59, 999),
      completedAt: DateTime(2026, 1, 1),
    ));
    registerFallbackValue(Goal(
      id: 'x',
      title: 'x',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 31),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      archived: false,
    ));
    registerFallbackValue(GoalActivity(
      id: 'x',
      goalId: 'x',
      title: 'x',
      recurrence: Recurrence.none,
      createdAt: DateTime(2026, 1, 1),
    ));
  });

  setUp(() {
    goals = _MockGoals();
    activities = _MockActivities();
    completions = _MockCompletions();
    when(() => goals.getAll()).thenAnswer((_) async => [makeGoal()]);
    when(() => activities.listByGoal(any()))
        .thenAnswer((_) async => [makeActivity()]);
    when(() => completions.findByActivityInPeriod(any(),
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'))).thenAnswer((_) async => null);
  });

  blocTest<GoalBloc, GoalState>(
    'GoalsSubscriptionRequested emits loaded with one goal and one activity, no completion',
    build: () => GoalBloc(
      goalRepo: goals,
      activityRepo: activities,
      completionRepo: completions,
      uuid: const Uuid(),
      now: () => DateTime(2026, 6, 17),
    ),
    act: (b) => b.add(const GoalsSubscriptionRequested()),
    expect: () => [
      const GoalLoading(),
      predicate<GoalState>((s) =>
          s is GoalsLoaded &&
          s.goals.length == 1 &&
          s.activitiesByGoalId['g1']!.length == 1 &&
          s.completionsByActivityId.isEmpty),
    ],
  );

  blocTest<GoalBloc, GoalState>(
    'ActivityCompletionToggled inserts a completion for the current period',
    build: () {
      when(() => completions.insert(any())).thenAnswer((_) async {});
      return GoalBloc(
        goalRepo: goals,
        activityRepo: activities,
        completionRepo: completions,
        uuid: const Uuid(),
        now: () => DateTime(2026, 6, 17),
      );
    },
    act: (b) async {
      b.add(const GoalsSubscriptionRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const ActivityCompletionToggled(goalId: 'g1', activityId: 'a1'));
    },
    verify: (_) {
      final captured = verify(() => completions.insert(captureAny()))
          .captured
          .single as ActivityCompletion;
      expect(captured.activityId, 'a1');
      expect(captured.periodStart, DateTime(2026, 6, 15));
      expect(captured.periodEnd, DateTime(2026, 6, 21, 23, 59, 59, 999));
    },
  );

  blocTest<GoalBloc, GoalState>(
    'GoalUpdated calls repo.update with a refreshed updatedAt',
    build: () {
      when(() => goals.update(any())).thenAnswer((_) async {});
      return GoalBloc(
        goalRepo: goals,
        activityRepo: activities,
        completionRepo: completions,
        uuid: const Uuid(),
        now: () => DateTime(2026, 6, 17, 12),
      );
    },
    act: (b) => b.add(GoalUpdated(makeGoal().copyWith(
      title: 'Renamed',
      description: 'new desc',
      endDate: DateTime(2026, 9, 30),
    ))),
    verify: (_) {
      final captured =
          verify(() => goals.update(captureAny())).captured.single as Goal;
      expect(captured.title, 'Renamed');
      expect(captured.description, 'new desc');
      expect(captured.endDate, DateTime(2026, 9, 30));
      expect(captured.updatedAt, DateTime(2026, 6, 17, 12));
    },
  );

  blocTest<GoalBloc, GoalState>(
    'ActivityCountLogged adds delta and records current period completion',
    build: () {
      var currentActivity = makeActivity();
      when(() => activities.update(any())).thenAnswer((invocation) async {
        currentActivity = invocation.positionalArguments[0] as GoalActivity;
      });
      when(() => activities.getById(any()))
          .thenAnswer((invocation) async => currentActivity);
      when(() => completions.insert(any())).thenAnswer((_) async {});
      return GoalBloc(
        goalRepo: goals,
        activityRepo: activities,
        completionRepo: completions,
        uuid: const Uuid(),
        now: () => DateTime(2026, 6, 17),
      );
    },
    act: (b) async {
      b.add(const GoalsSubscriptionRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const ActivityCountLogged(activityId: 'a1', delta: 5));
    },
    verify: (_) {
      final captured = verify(() => activities.update(captureAny()))
          .captured
          .single as GoalActivity;
      expect(captured.totalCount, 5);
      final completion = verify(() => completions.insert(captureAny()))
          .captured
          .single as ActivityCompletion;
      expect(completion.activityId, 'a1');
      expect(completion.periodStart, DateTime(2026, 6, 15));
      expect(completion.periodEnd, DateTime(2026, 6, 21, 23, 59, 59, 999));
    },
  );

  blocTest<GoalBloc, GoalState>(
    'ActivityDurationLogged accumulates seconds and reuses current period completion',
    build: () {
      var currentActivity = makeActivity();
      when(() => activities.update(any())).thenAnswer((invocation) async {
        currentActivity = invocation.positionalArguments[0] as GoalActivity;
      });
      when(() => activities.getById(any()))
          .thenAnswer((invocation) async => currentActivity);
      var existingCompletion = false;
      when(() => completions.findByActivityInPeriod(any(),
          periodStart: any(named: 'periodStart'),
          periodEnd: any(named: 'periodEnd'))).thenAnswer((_) async {
        if (!existingCompletion) return null;
        return ActivityCompletion(
          id: 'c1',
          activityId: 'a1',
          periodStart: DateTime(2026, 6, 15),
          periodEnd: DateTime(2026, 6, 21, 23, 59, 59, 999),
          completedAt: DateTime(2026, 6, 17),
        );
      });
      when(() => completions.insert(any())).thenAnswer((_) async {
        existingCompletion = true;
      });
      return GoalBloc(
        goalRepo: goals,
        activityRepo: activities,
        completionRepo: completions,
        uuid: const Uuid(),
        now: () => DateTime(2026, 6, 17),
      );
    },
    act: (b) async {
      b.add(const GoalsSubscriptionRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const ActivityDurationLogged(activityId: 'a1', seconds: 600));
      await Future<void>.delayed(Duration.zero);
      b.add(const ActivityDurationLogged(activityId: 'a1', seconds: 60));
    },
    verify: (_) {
      final updates = verify(() => activities.update(captureAny()))
          .captured
          .cast<GoalActivity>();
      expect(updates.first.totalSeconds, 600);
      expect(updates.last.totalSeconds, 660);
      verify(() => completions.insert(any())).called(1);
    },
  );
}
