// lib/features/countdown/domain/countdown_event.dart
import 'package:equatable/equatable.dart';

class CountdownEvent extends Equatable {
  const CountdownEvent({
    required this.id,
    required this.title,
    required this.targetDate,
    required this.createdAt,
    required this.archived,
    this.notes,
  });

  final String id;
  final String title;
  final String? notes;
  final DateTime targetDate;
  final DateTime createdAt;
  final bool archived;

  /// Whole-day delta (positive = future). Counted by *date* (midnight-to-midnight),
  /// not by elapsed milliseconds, so time-of-day doesn't change the answer.
  int daysRemaining({DateTime? on}) {
    final now = on ?? DateTime.now();
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return target.difference(today).inDays;
  }

  CountdownEvent copyWith({String? title, String? notes, DateTime? targetDate, bool? archived}) =>
      CountdownEvent(
        id: id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        targetDate: targetDate ?? this.targetDate,
        createdAt: createdAt,
        archived: archived ?? this.archived,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'notes': notes,
        'target_date': targetDate.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'archived': archived ? 1 : 0,
      };

  factory CountdownEvent.fromMap(Map<String, Object?> m) => CountdownEvent(
        id: m['id'] as String,
        title: m['title'] as String,
        notes: m['notes'] as String?,
        targetDate: DateTime.fromMillisecondsSinceEpoch(m['target_date'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        archived: (m['archived'] as int) == 1,
      );

  @override
  List<Object?> get props => [id, title, notes, targetDate, createdAt, archived];
}