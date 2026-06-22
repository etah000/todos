// lib/features/logs/domain/log_entry.dart
import 'package:equatable/equatable.dart';

class LogEntry extends Equatable {
  const LogEntry({
    required this.id,
    required this.logItemId,
    required this.value,
    required this.loggedAt,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String logItemId;
  final double value;
  final String? notes;
  final DateTime loggedAt;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'log_item_id': logItemId,
        'value': value,
        'notes': notes,
        'logged_at': loggedAt.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory LogEntry.fromMap(Map<String, Object?> m) => LogEntry(
        id: m['id'] as String,
        logItemId: m['log_item_id'] as String,
        value: (m['value'] as num).toDouble(),
        notes: m['notes'] as String?,
        loggedAt: DateTime.fromMillisecondsSinceEpoch(m['logged_at'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  @override
  List<Object?> get props => [id, logItemId, value, notes, loggedAt, createdAt];
}