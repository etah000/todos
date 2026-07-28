// lib/features/logs/presentation/bloc/log_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/log_entry.dart';
import '../../domain/log_item.dart';

abstract class LogState extends Equatable {
  const LogState();
  @override
  List<Object?> get props => [];
}

class LogInitial extends LogState {
  const LogInitial();
}

class LogLoading extends LogState {
  const LogLoading();
}

class LogLoaded extends LogState {
  const LogLoaded({required this.items, required this.entriesByItemId});
  final List<LogItem> items;
  final Map<String, List<LogEntry>> entriesByItemId;

  LogLoaded copyWith({
    List<LogItem>? items,
    Map<String, List<LogEntry>>? entriesByItemId,
  }) =>
      LogLoaded(
        items: items ?? this.items,
        entriesByItemId: entriesByItemId ?? this.entriesByItemId,
      );

  @override
  List<Object?> get props => [items, entriesByItemId];
}

class LogErrorState extends LogState {
  const LogErrorState(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
