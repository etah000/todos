// lib/features/goals/domain/goal.dart
import 'package:equatable/equatable.dart';

class Goal extends Equatable {
  const Goal({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;

  bool isActive({DateTime? on}) {
    final t = on ?? DateTime.now();
    return !t.isBefore(_day(startDate)) && !t.isAfter(_day(endDate));
  }

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  Goal copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? updatedAt,
    bool? archived,
  }) =>
      Goal(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        archived: archived ?? this.archived,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'start_date': startDate.millisecondsSinceEpoch,
        'end_date': endDate.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'archived': archived ? 1 : 0,
      };

  factory Goal.fromMap(Map<String, Object?> m) => Goal(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        startDate: DateTime.fromMillisecondsSinceEpoch(m['start_date'] as int),
        endDate: DateTime.fromMillisecondsSinceEpoch(m['end_date'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
        archived: (m['archived'] as int) == 1,
      );

  @override
  List<Object?> get props => [id, title, description, startDate, endDate, createdAt, updatedAt, archived];
}