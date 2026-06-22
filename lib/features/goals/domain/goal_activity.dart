// lib/features/goals/domain/goal_activity.dart
import 'package:equatable/equatable.dart';

import '../../todos/domain/recurrence.dart';

class GoalActivity extends Equatable {
  const GoalActivity({
    required this.id,
    required this.goalId,
    required this.title,
    required this.recurrence,
    required this.createdAt,
    this.recurrenceConfig,
  });

  final String id;
  final String goalId;
  final String title;
  final Recurrence recurrence;
  final String? recurrenceConfig;
  final DateTime createdAt;

  GoalActivity copyWith({String? title, Recurrence? recurrence, String? recurrenceConfig}) => GoalActivity(
        id: id,
        goalId: goalId,
        title: title ?? this.title,
        recurrence: recurrence ?? this.recurrence,
        recurrenceConfig: recurrenceConfig ?? this.recurrenceConfig,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'goal_id': goalId,
        'title': title,
        'recurrence_type': recurrence.wire,
        'recurrence_config': recurrenceConfig,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory GoalActivity.fromMap(Map<String, Object?> m) => GoalActivity(
        id: m['id'] as String,
        goalId: m['goal_id'] as String,
        title: m['title'] as String,
        recurrence: Recurrence.parse(m['recurrence_type'] as String?),
        recurrenceConfig: m['recurrence_config'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  @override
  List<Object?> get props => [id, goalId, title, recurrence, recurrenceConfig, createdAt];
}