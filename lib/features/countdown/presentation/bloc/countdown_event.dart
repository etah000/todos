// lib/features/countdown/presentation/bloc/countdown_event.dart
import 'package:equatable/equatable.dart';

abstract class CountdownEvent extends Equatable {
  const CountdownEvent();
  @override
  List<Object?> get props => [];
}

class CountdownSubscriptionRequested extends CountdownEvent {
  const CountdownSubscriptionRequested();
}

class CountdownCreated extends CountdownEvent {
  const CountdownCreated({required this.title, required this.targetDate, this.notes});
  final String title;
  final DateTime? targetDate;
  final String? notes;
  @override
  List<Object?> get props => [title, targetDate, notes];
}

class CountdownDeleted extends CountdownEvent {
  const CountdownDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}