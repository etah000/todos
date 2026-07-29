// lib/features/goals/presentation/bloc/goal_event.dart
import 'package:equatable/equatable.dart';

import '../../../todos/domain/recurrence.dart';
import '../../domain/goal_activity.dart';

abstract class GoalEvent extends Equatable {
  const GoalEvent();
  @override
  List<Object?> get props => [];
}

class GoalsSubscriptionRequested extends GoalEvent {
  const GoalsSubscriptionRequested();
}

class CategoryCreated extends GoalEvent {
  const CategoryCreated({required this.title, this.description});
  final String title;
  final String? description;
  @override
  List<Object?> get props => [title, description];
}

class CategoryUpdated extends GoalEvent {
  const CategoryUpdated(this.category);
  final dynamic category;
  @override
  List<Object?> get props => [category];
}

class CategoryDeleted extends GoalEvent {
  const CategoryDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class GoalActivityCreated extends GoalEvent {
  const GoalActivityCreated({
    required this.categoryId,
    required this.title,
    required this.metric,
    required this.recurrence,
    required this.startDate,
    required this.targetValue,
    required this.targetUnit,
    this.recurrenceConfig,
  });
  final String categoryId;
  final String title;
  final ActivityMetric metric;
  final Recurrence recurrence;
  final String? recurrenceConfig;
  final DateTime startDate;
  final double targetValue;
  final dynamic targetUnit;
  @override
  List<Object?> get props => [
        categoryId, title, metric, recurrence, recurrenceConfig,
        startDate, targetValue, targetUnit,
      ];
}

class GoalActivityUpdated extends GoalEvent {
  const GoalActivityUpdated(this.activity);
  final GoalActivity activity;
  @override
  List<Object?> get props => [activity];
}

class GoalActivityDeleted extends GoalEvent {
  const GoalActivityDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class GoalLogBooleanToggled extends GoalEvent {
  const GoalLogBooleanToggled({
    required this.goalActivityId,
    required this.periodStart,
    required this.periodEnd,
  });
  final String goalActivityId;
  final DateTime periodStart;
  final DateTime periodEnd;
  @override
  List<Object?> get props => [goalActivityId, periodStart, periodEnd];
}

class GoalLogCountAdded extends GoalEvent {
  const GoalLogCountAdded({required this.goalActivityId, required this.delta});
  final String goalActivityId;
  final int delta;
  @override
  List<Object?> get props => [goalActivityId, delta];
}

class GoalLogDurationAdded extends GoalEvent {
  const GoalLogDurationAdded({required this.goalActivityId, required this.seconds});
  final String goalActivityId;
  final int seconds;
  @override
  List<Object?> get props => [goalActivityId, seconds];
}

class GoalLogDeleted extends GoalEvent {
  const GoalLogDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class GoalLogEdited extends GoalEvent {
  const GoalLogEdited(this.log);
  final dynamic log;
  @override
  List<Object?> get props => [log];
}