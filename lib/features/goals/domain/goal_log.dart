import 'package:equatable/equatable.dart';

class GoalLog extends Equatable {
  const GoalLog({
    required this.id,
    required this.goalActivityId,
    required this.value,
    required this.loggedAt,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String goalActivityId;
  final double value;
  final String? notes;
  final DateTime loggedAt;
  final DateTime createdAt;

  GoalLog copyWith({double? value, String? notes, DateTime? loggedAt}) =>
      GoalLog(
        id: id,
        goalActivityId: goalActivityId,
        value: value ?? this.value,
        notes: notes ?? this.notes,
        loggedAt: loggedAt ?? this.loggedAt,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'goal_activity_id': goalActivityId,
        'value': value,
        'notes': notes,
        'logged_at': loggedAt.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory GoalLog.fromMap(Map<String, Object?> m) => GoalLog(
        id: m['id'] as String,
        goalActivityId: m['goal_activity_id'] as String,
        value: (m['value'] as num).toDouble(),
        notes: m['notes'] as String?,
        loggedAt: DateTime.fromMillisecondsSinceEpoch(m['logged_at'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  @override
  List<Object?> get props => [id, goalActivityId, value, notes, loggedAt, createdAt];
}