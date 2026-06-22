// lib/features/logs/presentation/bloc/log_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/log_entry_repository.dart';
import '../../data/log_item_repository.dart';
import '../../domain/log_entry.dart';
import '../../domain/log_item.dart';
import 'log_event.dart';
import 'log_state.dart';

class LogBloc extends Bloc<LogEvent, LogState> {
  LogBloc({
    required LogItemRepository itemRepo,
    required LogEntryRepository entryRepo,
    required Uuid uuid,
    DateTime Function()? now,
  })  : _items = itemRepo,
        _entries = entryRepo,
        _uuid = uuid,
        _now = now ?? DateTime.now,
        super(const LogInitial()) {
    on<LogSubscriptionRequested>(_onSubscribe);
    on<LogItemCreated>(_onItemCreated);
    on<LogEntryAdded>(_onEntryAdded);
  }

  final LogItemRepository _items;
  final LogEntryRepository _entries;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> _onSubscribe(LogSubscriptionRequested e, Emitter<LogState> emit) async {
    emit(const LogLoading());
    try {
      final items = await _items.getAll();
      final grouped = <String, List<LogEntry>>{};
      for (final item in items) {
        grouped[item.id] = await _entries.listByItemInRange(
          item.id,
          from: DateTime.fromMillisecondsSinceEpoch(0),
          to: DateTime.now().add(const Duration(days: 1)),
        );
      }
      emit(LogLoaded(items: items, entriesByItemId: grouped));
    } catch (err) {
      emit(LogErrorState(err.toString()));
    }
  }

  Future<void> _onItemCreated(LogItemCreated e, Emitter<LogState> emit) async {
    final item = LogItem(
      id: _uuid.v4(),
      name: e.name,
      unit: e.unit,
      color: e.color,
      createdAt: _now(),
      archived: false,
    );
    await _items.insert(item);
    add(const LogSubscriptionRequested());
  }

  Future<void> _onEntryAdded(LogEntryAdded e, Emitter<LogState> emit) async {
    final entry = LogEntry(
      id: _uuid.v4(),
      logItemId: e.logItemId,
      value: e.value,
      notes: e.notes,
      loggedAt: e.loggedAt ?? _now(),
      createdAt: _now(),
    );
    await _entries.insert(entry);
    add(const LogSubscriptionRequested());
  }
}