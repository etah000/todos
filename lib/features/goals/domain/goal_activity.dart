// lib/features/goals/domain/goal_activity.dart
import 'package:equatable/equatable.dart';

import '../../todos/domain/recurrence.dart';

/// What kind of measurement this activity tracks. Old rows default to
/// [boolean] (the original yes/no done-this-period behavior).
enum ActivityMetric {
  boolean('boolean'),
  count('count'),
  duration('duration');

  const ActivityMetric(this.wire);
  final String wire;

  static ActivityMetric parse(String? wire) {
    for (final m in ActivityMetric.values) {
      if (m.wire == wire) return m;
    }
    return ActivityMetric.boolean;
  }
}

class GoalActivity extends Equatable {
  const GoalActivity({
    required this.id,
    required this.goalId,
    required this.title,
    required this.recurrence,
    required this.createdAt,
    this.recurrenceConfig,
    this.metric = ActivityMetric.boolean,
    this.totalCount = 0,
    this.totalSeconds = 0,
  });

  final String id;
  final String goalId;
  final String title;
  final Recurrence recurrence;
  final String? recurrenceConfig;
  final DateTime createdAt;
  final ActivityMetric metric;
  final int totalCount;
  final int totalSeconds;

  GoalActivity copyWith({
    String? title,
    Recurrence? recurrence,
    String? recurrenceConfig,
    ActivityMetric? metric,
    int? totalCount,
    int? totalSeconds,
  }) =>
      GoalActivity(
        id: id,
        goalId: goalId,
        title: title ?? this.title,
        recurrence: recurrence ?? this.recurrence,
        recurrenceConfig: recurrenceConfig ?? this.recurrenceConfig,
        createdAt: createdAt,
        metric: metric ?? this.metric,
        totalCount: totalCount ?? this.totalCount,
        totalSeconds: totalSeconds ?? this.totalSeconds,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'goal_id': goalId,
        'title': title,
        'recurrence_type': recurrence.wire,
        'recurrence_config': recurrenceConfig,
        'created_at': createdAt.millisecondsSinceEpoch,
        'metric': metric.wire,
        'total_count': totalCount,
        'total_seconds': totalSeconds,
      };

  factory GoalActivity.fromMap(Map<String, Object?> m) => GoalActivity(
        id: m['id'] as String,
        goalId: m['goal_id'] as String,
        title: m['title'] as String,
        recurrence: Recurrence.parse(m['recurrence_type'] as String?),
        recurrenceConfig: m['recurrence_config'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        metric: ActivityMetric.parse(m['metric'] as String?),
        totalCount: (m['total_count'] as int?) ?? 0,
        totalSeconds: (m['total_seconds'] as int?) ?? 0,
      );

  @override
  List<Object?> get props => [
        id, goalId, title, recurrence, recurrenceConfig, createdAt,
        metric, totalCount, totalSeconds,
      ];
}
