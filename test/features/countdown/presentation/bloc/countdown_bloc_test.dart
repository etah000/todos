// test/features/countdown/presentation/bloc/countdown_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todos/features/countdown/data/countdown_repository.dart';
import 'package:todos/features/countdown/domain/countdown_event.dart' as domain;
import 'package:todos/features/countdown/presentation/bloc/countdown_bloc.dart';
import 'package:todos/features/countdown/presentation/bloc/countdown_event.dart';
import 'package:todos/features/countdown/presentation/bloc/countdown_state.dart';
import 'package:uuid/uuid.dart';

class _MockRepo extends Mock implements CountdownRepository {}

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(domain.CountdownEvent(
      id: 'x', title: 'x', targetDate: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1), archived: false,
    ));
  });

  setUp(() {
    repo = _MockRepo();
    when(() => repo.getAll()).thenAnswer((_) async => []);
  });

  blocTest<CountdownBloc, CountdownState>(
    'SubscriptionRequested emits loaded with events',
    build: () {
      when(() => repo.getAll()).thenAnswer((_) async => [
            domain.CountdownEvent(
              id: 'e1', title: 'NYE',
              targetDate: DateTime(2027, 1, 1),
              createdAt: DateTime(2026, 6, 1), archived: false,
            ),
          ]);
      return CountdownBloc(repo: repo, uuid: const Uuid());
    },
    act: (b) => b.add(const CountdownSubscriptionRequested()),
    expect: () => [
      const CountdownLoading(),
      predicate<CountdownState>((s) => s is CountdownLoaded && s.events.length == 1),
    ],
  );

  blocTest<CountdownBloc, CountdownState>(
    'CountdownCreated inserts and reloads',
    build: () {
      when(() => repo.insert(any())).thenAnswer((_) async {});
      return CountdownBloc(repo: repo, uuid: const Uuid());
    },
    act: (b) => b.add(CountdownCreated(title: 'Trip', targetDate: DateTime(2026, 7, 1))),
    verify: (_) => verify(() => repo.insert(any())).called(1),
  );

  blocTest<CountdownBloc, CountdownState>(
    'CountdownUpdated calls repo.update and reloads',
    build: () {
      when(() => repo.update(any())).thenAnswer((_) async {});
      return CountdownBloc(repo: repo, uuid: const Uuid());
    },
    act: (b) => b.add(CountdownUpdated(
      domain.CountdownEvent(
        id: 'e1',
        title: 'Renamed',
        targetDate: DateTime(2028, 1, 1),
        createdAt: DateTime(2026, 6, 1),
        archived: false,
      ),
    )),
    verify: (_) {
      verify(() => repo.update(any())).called(1);
    },
  );
}