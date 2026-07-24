// lib/features/countdown/presentation/bloc/countdown_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/countdown_repository.dart';
import '../../domain/countdown_event.dart' as domain;
import 'countdown_event.dart';
import 'countdown_state.dart';

class CountdownBloc extends Bloc<CountdownEvent, CountdownState> {
  CountdownBloc({
    required CountdownRepository repo,
    required Uuid uuid,
    DateTime Function()? now,
  })  : _repo = repo,
        _uuid = uuid,
        _now = now ?? DateTime.now,
        super(const CountdownInitial()) {
    on<CountdownSubscriptionRequested>(_onSubscribe);
    on<CountdownCreated>(_onCreated);
    on<CountdownUpdated>(_onUpdated);
    on<CountdownDeleted>(_onDeleted);
  }

  final CountdownRepository _repo;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> _onSubscribe(CountdownSubscriptionRequested e, Emitter<CountdownState> emit) async {
    emit(const CountdownLoading());
    try {
      final events = await _repo.getAll();
      emit(CountdownLoaded(events: events));
    } catch (err) {
      emit(CountdownErrorState(err.toString()));
    }
  }

  Future<void> _onCreated(CountdownCreated e, Emitter<CountdownState> emit) async {
    if (e.targetDate == null) return;
    final at = _now();
    final ev = domain.CountdownEvent(
      id: _uuid.v4(),
      title: e.title,
      notes: e.notes,
      targetDate: e.targetDate!,
      createdAt: at,
      archived: false,
    );
    await _repo.insert(ev);
    add(const CountdownSubscriptionRequested());
  }

  Future<void> _onUpdated(CountdownUpdated e, Emitter<CountdownState> emit) async {
    await _repo.update(e.event);
    add(const CountdownSubscriptionRequested());
  }

  Future<void> _onDeleted(CountdownDeleted e, Emitter<CountdownState> emit) async {
    await _repo.delete(e.id);
    add(const CountdownSubscriptionRequested());
  }
}