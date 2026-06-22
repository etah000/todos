// lib/features/goals/presentation/bloc/goal_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/activity_completion_repository.dart';
import '../../data/goal_activity_repository.dart';
import '../../data/goal_repository.dart';
import '../../domain/activity_completion.dart';
import '../../domain/goal.dart';
import '../../domain/goal_activity.dart';
import '../../../todos/domain/recurrence.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  GoalBloc({
    required GoalRepository goalRepo,
    required GoalActivityRepository activityRepo,
    required ActivityCompletionRepository completionRepo,
    required Uuid uuid,
    DateTime Function()? now,
  })  : _goals = goalRepo,
        _activities = activityRepo,
        _completions = completionRepo,
        _uuid = uuid,
        _now = now ?? DateTime.now,
        super(const GoalInitial()) {
    on<GoalsSubscriptionRequested>(_onSubscribe);
    on<GoalCreated>(_onCreated);
    on<GoalDeleted>(_onDeleted);
    on<ActivityCreated>(_onActivityCreated);
    on<ActivityDeleted>(_onActivityDeleted);
    on<ActivityCompletionToggled>(_onToggled);
  }

  final GoalRepository _goals;
  final GoalActivityRepository _activities;
  final ActivityCompletionRepository _completions;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> _onSubscribe(GoalsSubscriptionRequested e, Emitter<GoalState> emit) async {
    emit(const GoalLoading());
    try {
      final goals = await _goals.getAll();
      final activitiesByGoal = <String, List<GoalActivity>>{};
      final completionsByActivity = <String, ActivityCompletion>{};
      final at = _now();
      for (final g in goals) {
        final acts = await _activities.listByGoal(g.id);
        activitiesByGoal[g.id] = acts;
        for (final a in acts) {
          final (start, end) = a.recurrence.periodFor(a.createdAt, at: at);
          final c = await _completions.findByActivityInPeriod(
            a.id, periodStart: start, periodEnd: end,
          );
          if (c != null) completionsByActivity[a.id] = c;
        }
      }
      emit(GoalsLoaded(
        goals: goals,
        activitiesByGoalId: activitiesByGoal,
        completionsByActivityId: completionsByActivity,
      ));
    } catch (err) {
      emit(GoalErrorState(err.toString()));
    }
  }

  Future<void> _onCreated(GoalCreated e, Emitter<GoalState> emit) async {
    final at = _now();
    final g = Goal(
      id: _uuid.v4(),
      title: e.title,
      description: e.description,
      startDate: e.startDate,
      endDate: e.endDate,
      createdAt: at,
      updatedAt: at,
      archived: false,
    );
    await _goals.insert(g);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onDeleted(GoalDeleted e, Emitter<GoalState> emit) async {
    await _goals.delete(e.id);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onActivityCreated(ActivityCreated e, Emitter<GoalState> emit) async {
    final a = GoalActivity(
      id: _uuid.v4(),
      goalId: e.goalId,
      title: e.title,
      recurrence: e.recurrence,
      createdAt: _now(),
    );
    await _activities.insert(a);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onActivityDeleted(ActivityDeleted e, Emitter<GoalState> emit) async {
    await _activities.delete(e.activityId);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onToggled(ActivityCompletionToggled e, Emitter<GoalState> emit) async {
    final at = _now();
    final activities = (state is GoalsLoaded)
        ? (state as GoalsLoaded).activitiesByGoalId[e.goalId] ?? const <GoalActivity>[]
        : const <GoalActivity>[];
    final activity = activities.firstWhere(
      (a) => a.id == e.activityId,
      orElse: () => GoalActivity(
        id: e.activityId, goalId: e.goalId, title: '',
        recurrence: Recurrence.none, createdAt: at,
      ),
    );
    final (start, end) = activity.recurrence.periodFor(activity.createdAt, at: at);
    final existing = await _completions.findByActivityInPeriod(
      e.activityId, periodStart: start, periodEnd: end,
    );
    if (existing == null) {
      final c = ActivityCompletion(
        id: _uuid.v4(),
        activityId: e.activityId,
        periodStart: start,
        periodEnd: end,
        completedAt: at,
      );
      await _completions.insert(c);
    }
    add(const GoalsSubscriptionRequested());
  }
}