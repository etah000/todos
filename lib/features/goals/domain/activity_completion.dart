// lib/features/goals/domain/activity_completion.dart
import 'package:equatable/equatable.dart';

class ActivityCompletion extends Equatable {
  const ActivityCompletion({
    required this.id,
    required this.activityId,
    required this.periodStart,
    required this.periodEnd,
    required this.completedAt,
    this.notes,
  });

  final String id;
  final String activityId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime completedAt;
  final String? notes;

  Map<String, Object?> toMap() => {
        'id': id,
        'activity_id': activityId,
        'period_start': periodStart.millisecondsSinceEpoch,
        'period_end': periodEnd.millisecondsSinceEpoch,
        'completed_at': completedAt.millisecondsSinceEpoch,
        'notes': notes,
      };

  factory ActivityCompletion.fromMap(Map<String, Object?> m) => ActivityCompletion(
        id: m['id'] as String,
        activityId: m['activity_id'] as String,
        periodStart: DateTime.fromMillisecondsSinceEpoch(m['period_start'] as int),
        periodEnd: DateTime.fromMillisecondsSinceEpoch(m['period_end'] as int),
        completedAt: DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int),
        notes: m['notes'] as String?,
      );

  @override
  List<Object?> get props => [id, activityId, periodStart, periodEnd, completedAt, notes];
}