// lib/features/goals/presentation/bloc/goal_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/activity_completion.dart';
import '../../domain/goal.dart';
import '../../domain/goal_activity.dart';

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
    required this.goals,
    required this.activitiesByGoalId,
    required this.completionsByActivityId,
  });
  final List<Goal> goals;
  final Map<String, List<GoalActivity>> activitiesByGoalId;
  final Map<String, ActivityCompletion> completionsByActivityId;

  @override
  List<Object?> get props => [goals, activitiesByGoalId, completionsByActivityId];
}

class GoalErrorState extends GoalState {
  const GoalErrorState(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}