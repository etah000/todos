// test/features/logs/presentation/bloc/log_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todos/features/logs/data/log_entry_repository.dart';
import 'package:todos/features/logs/data/log_item_repository.dart';
import 'package:todos/features/logs/domain/log_entry.dart';
import 'package:todos/features/logs/domain/log_item.dart';
import 'package:todos/features/logs/presentation/bloc/log_bloc.dart';
import 'package:todos/features/logs/presentation/bloc/log_event.dart';
import 'package:todos/features/logs/presentation/bloc/log_state.dart';
import 'package:uuid/uuid.dart';

class _MockItems extends Mock implements LogItemRepository {}

class _MockEntries extends Mock implements LogEntryRepository {}

void main() {
  late _MockItems items;
  late _MockEntries entries;

  setUpAll(() {
    registerFallbackValue(
      LogEntry(
        id: 'x',
        logItemId: 'x',
        value: 0,
        loggedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    items = _MockItems();
    entries = _MockEntries();
    when(() => items.getAll(includeArchived: any(named: 'includeArchived')))
        .thenAnswer(
      (_) async => [
        LogItem(
          id: 'i1',
          name: 'weight',
          createdAt: DateTime(2026, 1, 1),
          archived: false,
        ),
      ],
    );
    when(
      () => entries.listByItemInRange(
        any(),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => []);
  });

  blocTest<LogBloc, LogState>(
    'SubscriptionRequested emits loaded with items and empty per-item entries',
    build: () => LogBloc(
      itemRepo: items,
      entryRepo: entries,
      uuid: const Uuid(),
    ),
    act: (b) => b.add(const LogSubscriptionRequested()),
    expect: () => [
      const LogLoading(),
      predicate<LogState>(
        (s) =>
            s is LogLoaded &&
            s.items.length == 1 &&
            s.entriesByItemId['i1']!.isEmpty,
      ),
    ],
  );

  blocTest<LogBloc, LogState>(
    'EntryAdded inserts an entry and reloads',
    build: () {
      when(() => entries.insert(any())).thenAnswer((_) async {});
      return LogBloc(itemRepo: items, entryRepo: entries, uuid: const Uuid());
    },
    act: (b) => b.add(const LogEntryAdded(logItemId: 'i1', value: 81.0)),
    verify: (_) => verify(() => entries.insert(any())).called(1),
  );
}
