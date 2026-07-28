// lib/features/logs/presentation/bloc/log_event.dart
import 'package:equatable/equatable.dart';

abstract class LogEvent extends Equatable {
  const LogEvent();
  @override
  List<Object?> get props => [];
}

class LogSubscriptionRequested extends LogEvent {
  const LogSubscriptionRequested();
}

class LogItemCreated extends LogEvent {
  const LogItemCreated({required this.name, this.unit, this.color});
  final String name;
  final String? unit;
  final int? color;
  @override
  List<Object?> get props => [name, unit, color];
}

class LogEntryAdded extends LogEvent {
  const LogEntryAdded({
    required this.logItemId,
    required this.value,
    this.notes,
    this.loggedAt,
  });
  final String logItemId;
  final double value;
  final String? notes;
  final DateTime? loggedAt;
  @override
  List<Object?> get props => [logItemId, value, notes, loggedAt];
}

class LogItemDeleted extends LogEvent {
  const LogItemDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
