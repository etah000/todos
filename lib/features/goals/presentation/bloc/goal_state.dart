// lib/features/goals/presentation/bloc/goal_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/category.dart';
import '../../domain/goal_activity.dart';
import '../../domain/goal_log.dart';

abstract class GoalState extends Equatable {
  const GoalState();
  @override
  List<Object?> get props => [];
}

class GoalInitial extends GoalState {
  const GoalInitial();
}

class GoalLoading extends GoalState {
  const GoalLoading();
}

class GoalsLoaded extends GoalState {
  const GoalsLoaded({
    required this.categories,
    required this.activitiesByCategoryId,
    required this.logsByActivityId,
  });
  final List<Category> categories;
  final Map<String, List<GoalActivity>> activitiesByCategoryId;
  final Map<String, List<GoalLog>> logsByActivityId;

  @override
  List<Object?> get props => [categories, activitiesByCategoryId, logsByActivityId];
}

class GoalErrorState extends GoalState {
  const GoalErrorState(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}