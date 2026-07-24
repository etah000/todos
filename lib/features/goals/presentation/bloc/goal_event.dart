// lib/features/goals/presentation/bloc/goal_event.dart
import 'package:equatable/equatable.dart';

import '../../../todos/domain/recurrence.dart';
import '../../domain/goal.dart';
import '../../domain/goal_activity.dart';

abstract class GoalEvent extends Equatable {
  const GoalEvent();
  @override
  List<Object?> get props => [];
}

class GoalsSubscriptionRequested extends GoalEvent {
  const GoalsSubscriptionRequested();
}

class GoalCreated extends GoalEvent {
  const GoalCreated({
    required this.title,
    required this.startDate,
    required this.endDate,
    this.description,
  });
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  @override
  List<Object?> get props => [title, description, startDate, endDate];
}

class GoalUpdated extends GoalEvent {
  const GoalUpdated(this.goal);
  final Goal goal;
  @override
  List<Object?> get props => [goal];
}

class GoalDeleted extends GoalEvent {
  const GoalDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class ActivityCreated extends GoalEvent {
  const ActivityCreated({
    required this.goalId,
    required this.title,
    required this.recurrence,
    this.metric = ActivityMetric.boolean,
  });
  final String goalId;
  final String title;
  final Recurrence recurrence;
  final ActivityMetric metric;
  @override
  List<Object?> get props => [goalId, title, recurrence, metric];
}

class ActivityUpdated extends GoalEvent {
  const ActivityUpdated(this.activity);
  final GoalActivity activity;
  @override
  List<Object?> get props => [activity];
}

class ActivityDeleted extends GoalEvent {
  const ActivityDeleted(this.activityId);
  final String activityId;
  @override
  List<Object?> get props => [activityId];
}

class ActivityCompletionToggled extends GoalEvent {
  const ActivityCompletionToggled({required this.goalId, required this.activityId});
  final String goalId;
  final String activityId;
  @override
  List<Object?> get props => [goalId, activityId];
}

/// Add [delta] to the activity's running totalCount (count metric only).
class ActivityCountLogged extends GoalEvent {
  const ActivityCountLogged({required this.activityId, required this.delta});
  final String activityId;
  final int delta;
  @override
  List<Object?> get props => [activityId, delta];
}

/// Add [seconds] to the activity's running totalSeconds (duration metric only).
class ActivityDurationLogged extends GoalEvent {
  const ActivityDurationLogged({required this.activityId, required this.seconds});
  final String activityId;
  final int seconds;
  @override
  List<Object?> get props => [activityId, seconds];
}