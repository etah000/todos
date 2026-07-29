// lib/features/goals/presentation/bloc/goal_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/category_repository.dart';
import '../../data/goal_activity_repository.dart';
import '../../data/goal_log_repository.dart';
import '../../domain/category.dart';
import '../../domain/goal_activity.dart';
import '../../domain/goal_log.dart';
import '../../domain/goal_progress_snapshot.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  GoalBloc({
    required CategoryRepository categoryRepo,
    required GoalActivityRepository activityRepo,
    required GoalLogRepository logRepo,
    required Uuid uuid,
    DateTime Function()? now,
  })  : _categories = categoryRepo,
        _activities = activityRepo,
        _logs = logRepo,
        _uuid = uuid,
        _now = now ?? DateTime.now,
        super(const GoalInitial()) {
    on<GoalsSubscriptionRequested>(_onSubscribe);
    on<CategoryCreated>(_onCategoryCreated);
    on<CategoryUpdated>(_onCategoryUpdated);
    on<CategoryDeleted>(_onCategoryDeleted);
    on<GoalActivityCreated>(_onActivityCreated);
    on<GoalActivityUpdated>(_onActivityUpdated);
    on<GoalActivityDeleted>(_onActivityDeleted);
    on<GoalLogBooleanToggled>(_onLogBooleanToggled);
    on<GoalLogCountAdded>(_onLogCountAdded);
    on<GoalLogDurationAdded>(_onLogDurationAdded);
    on<GoalLogDeleted>(_onLogDeleted);
    on<GoalLogEdited>(_onLogEdited);
  }

  final CategoryRepository _categories;
  final GoalActivityRepository _activities;
  final GoalLogRepository _logs;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> _onSubscribe(GoalsSubscriptionRequested e, Emitter<GoalState> emit) async {
    emit(const GoalLoading());
    try {
      final cats = await _categories.getAll();
      final activitiesByCat = <String, List<GoalActivity>>{};
      final logsByAct = <String, List<GoalLog>>{};
      final at = _now();
      for (final c in cats) {
        final acts = await _activities.listByCategory(c.id);
        activitiesByCat[c.id] = acts;
        for (final a in acts) {
          logsByAct[a.id] = await _logs.listByActivity(a.id);
        }
      }
      final withSnapshots = <String, List<GoalActivity>>{};
      activitiesByCat.forEach((catId, acts) {
        withSnapshots[catId] = [
          for (final a in acts)
            a.copyWith(
              progressSnapshot: GoalProgressSnapshot.compute(
                activity: a, now: at, logs: logsByAct[a.id] ?? const []),
            ),
        ];
      });
      emit(GoalsLoaded(
        categories: cats,
        activitiesByCategoryId: withSnapshots,
        logsByActivityId: logsByAct,
      ));
    } catch (err) {
      emit(GoalErrorState(err.toString()));
    }
  }

  Future<void> _onCategoryCreated(CategoryCreated e, Emitter<GoalState> emit) async {
    final at = _now();
    await _categories.insert(Category(
      id: _uuid.v4(), title: e.title, description: e.description,
      createdAt: at, updatedAt: at, archived: false,
    ));
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onCategoryUpdated(CategoryUpdated e, Emitter<GoalState> emit) async {
    await _categories.update(e.category.copyWith(updatedAt: _now()));
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onCategoryDeleted(CategoryDeleted e, Emitter<GoalState> emit) async {
    await _categories.delete(e.id);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onActivityCreated(GoalActivityCreated e, Emitter<GoalState> emit) async {
    final a = GoalActivity(
      id: _uuid.v4(), categoryId: e.categoryId, title: e.title,
      metric: e.metric, recurrence: e.recurrence, recurrenceConfig: e.recurrenceConfig,
      startDate: e.startDate, targetValue: e.targetValue, targetUnit: e.targetUnit,
      createdAt: _now(),
    );
    await _activities.insert(a);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onActivityUpdated(GoalActivityUpdated e, Emitter<GoalState> emit) async {
    await _activities.update(e.activity);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onActivityDeleted(GoalActivityDeleted e, Emitter<GoalState> emit) async {
    await _activities.delete(e.id);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onLogBooleanToggled(GoalLogBooleanToggled e, Emitter<GoalState> emit) async {
    final existing = await _logs.listByActivityInRange(
      e.goalActivityId, from: e.periodStart, to: e.periodEnd,
    );
    if (existing.isNotEmpty) {
      await _logs.delete(existing.first.id);
    } else {
      await _logs.insert(GoalLog(
        id: _uuid.v4(), goalActivityId: e.goalActivityId, value: 1.0,
        loggedAt: _now(), createdAt: _now(),
      ));
    }
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onLogCountAdded(GoalLogCountAdded e, Emitter<GoalState> emit) async {
    await _logs.insert(GoalLog(
      id: _uuid.v4(), goalActivityId: e.goalActivityId, value: e.delta.toDouble(),
      loggedAt: _now(), createdAt: _now(),
    ));
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onLogDurationAdded(GoalLogDurationAdded e, Emitter<GoalState> emit) async {
    await _logs.insert(GoalLog(
      id: _uuid.v4(), goalActivityId: e.goalActivityId, value: e.seconds.toDouble(),
      loggedAt: _now(), createdAt: _now(),
    ));
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onLogDeleted(GoalLogDeleted e, Emitter<GoalState> emit) async {
    await _logs.delete(e.id);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onLogEdited(GoalLogEdited e, Emitter<GoalState> emit) async {
    await _logs.update(e.log);
    add(const GoalsSubscriptionRequested());
  }
}