// lib/features/goals/presentation/bloc/goal_event.dart
import 'package:equatable/equatable.dart';

import '../../../todos/domain/recurrence.dart';

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
  });
  final String goalId;
  final String title;
  final Recurrence recurrence;
  @override
  List<Object?> get props => [goalId, title, recurrence];
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