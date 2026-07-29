import 'package:equatable/equatable.dart';

import '../../todos/domain/recurrence.dart';
import 'goal_progress_snapshot.dart';
import 'goal_target_unit.dart';

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
    required this.categoryId,
    required this.title,
    required this.recurrence,
    required this.startDate,
    required this.targetValue,
    required this.targetUnit,
    required this.createdAt,
    this.recurrenceConfig,
    this.metric = ActivityMetric.boolean,
    this.progressSnapshot,
  });

  final String id;
  final String categoryId;
  final String title;
  final Recurrence recurrence;
  final String? recurrenceConfig;
  final DateTime startDate;
  final double targetValue;
  final GoalTargetUnit targetUnit;
  final ActivityMetric metric;
  final DateTime createdAt;

  /// Populated by the bloc during subscription. Not persisted.
  final GoalProgressSnapshot? progressSnapshot;

  GoalActivity copyWith({
    String? title,
    Recurrence? recurrence,
    String? recurrenceConfig,
    DateTime? startDate,
    double? targetValue,
    GoalTargetUnit? targetUnit,
    ActivityMetric? metric,
    GoalProgressSnapshot? progressSnapshot,
  }) =>
      GoalActivity(
        id: id,
        categoryId: categoryId,
        title: title ?? this.title,
        recurrence: recurrence ?? this.recurrence,
        recurrenceConfig: recurrenceConfig ?? this.recurrenceConfig,
        startDate: startDate ?? this.startDate,
        targetValue: targetValue ?? this.targetValue,
        targetUnit: targetUnit ?? this.targetUnit,
        metric: metric ?? this.metric,
        createdAt: createdAt,
        progressSnapshot: progressSnapshot ?? this.progressSnapshot,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'category_id': categoryId,
        'title': title,
        'recurrence_type': recurrence.wire,
        'recurrence_config': recurrenceConfig,
        'start_date': startDate.millisecondsSinceEpoch,
        'target_value': targetValue,
        'target_unit': targetUnit.wire,
        'metric': metric.wire,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory GoalActivity.fromMap(Map<String, Object?> m) => GoalActivity(
        id: m['id'] as String,
        categoryId: m['category_id'] as String,
        title: m['title'] as String,
        recurrence: Recurrence.parse(m['recurrence_type'] as String?),
        recurrenceConfig: m['recurrence_config'] as String?,
        startDate: DateTime.fromMillisecondsSinceEpoch(m['start_date'] as int),
        targetValue: ((m['target_value'] as num?) ?? 1).toDouble(),
        targetUnit: GoalTargetUnit.parse(m['target_unit'] as String?),
        metric: ActivityMetric.parse(m['metric'] as String?),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  @override
  List<Object?> get props => [
        id, categoryId, title, recurrence, recurrenceConfig, startDate,
        targetValue, targetUnit, metric, createdAt,
      ];
}
