// lib/features/countdown/presentation/bloc/countdown_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/countdown_event.dart';

abstract class CountdownState extends Equatable {
  const CountdownState();
  @override
  List<Object?> get props => [];
}

class CountdownInitial extends CountdownState {
  const CountdownInitial();
}

class CountdownLoading extends CountdownState {
  const CountdownLoading();
}

class CountdownLoaded extends CountdownState {
  const CountdownLoaded({required this.events});
  final List<CountdownEvent> events;
  @override
  List<Object?> get props => [events];
}

class CountdownErrorState extends CountdownState {
  const CountdownErrorState(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}