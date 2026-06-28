// test/features/todos/presentation/bloc/todo_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todos/features/todos/data/todo_completion_repository.dart';
import 'package:todos/features/todos/data/todo_repository.dart';
import 'package:todos/features/todos/domain/recurrence.dart';
import 'package:todos/features/todos/domain/todo.dart';
import 'package:todos/features/todos/domain/todo_completion.dart';
import 'package:todos/features/todos/presentation/bloc/notification_scheduler.dart';
import 'package:todos/features/todos/presentation/bloc/todo_bloc.dart';
import 'package:todos/features/todos/presentation/bloc/todo_event.dart';
import 'package:todos/features/todos/presentation/bloc/todo_state.dart';
import 'package:uuid/uuid.dart';

class _MockTodoRepo extends Mock implements TodoRepository {}
class _MockCompletionRepo extends Mock implements TodoCompletionRepository {}
class _MockScheduler extends Mock implements NotificationScheduler {}
class _FixedUuid extends Mock implements Uuid {}

void main() {
  late _MockTodoRepo todoRepo;
  late _MockCompletionRepo completionRepo;
  late _MockScheduler scheduler;
  late _FixedUuid uuid;

  setUpAll(() {
    final now = DateTime(2026, 6, 1);
    registerFallbackValue(Recurrence.none);
    registerFallbackValue(Todo(
      id: 'fb',
      title: 'fb',
      createdAt: now,
      updatedAt: now,
      archived: false,
      recurrence: Recurrence.none,
    ));
    registerFallbackValue(TodoCompletion(
      id: 'fb',
      todoId: 'fb',
      periodStart: DateTime(2026, 1, 1),
      periodEnd: DateTime(2026, 1, 31, 23, 59, 59, 999),
      completedAt: DateTime(2026, 1, 1),
    ));
  });

  setUp(() {
    todoRepo = _MockTodoRepo();
    completionRepo = _MockCompletionRepo();
    scheduler = _MockScheduler();
    uuid = _FixedUuid();
    when(() => uuid.v4()).thenReturn('fixed-uuid');
    when(() => completionRepo.findByTodoInPeriod(
          any(),
          periodStart: any(named: 'periodStart'),
          periodEnd: any(named: 'periodEnd'),
        )).thenAnswer((_) async => null);
    when(() => scheduler.schedule(
          any(),
          any(),
          any(),
          recurrence: any(named: 'recurrence'),
        )).thenAnswer((_) async {});
    when(() => scheduler.cancel(any())).thenAnswer((_) async {});
  });

  Todo makeTodo({String id = 'a1', Recurrence r = Recurrence.monthly}) {
    final now = DateTime(2026, 6, 1);
    return Todo(
      id: id, title: 'rent', recurrence: r,
      createdAt: now, updatedAt: now, archived: false,
    );
  }

  group('TodosSubscription', () {
    blocTest<TodoBloc, TodoState>(
      'emits [loading, loaded] with items on Subscribe',
      build: () {
        when(() => todoRepo.getAll()).thenAnswer((_) async => [makeTodo()]);
        return TodoBloc(
          todoRepo: todoRepo,
          completionRepo: completionRepo,
          uuid: uuid,
          notifications: scheduler,
        );
      },
      act: (b) => b.add(const TodosSubscriptionRequested()),
      expect: () => [
        const TodosLoading(),
        predicate<TodoState>((s) => s is TodosLoaded && s.items.length == 1),
      ],
    );
  });

  group('TodoCompletionForCurrentPeriod', () {
    blocTest<TodoBloc, TodoState>(
      'records a completion with the current period for a monthly todo',
      build: () {
        when(() => todoRepo.getById('a1')).thenAnswer((_) async => makeTodo());
        when(() => completionRepo.insert(any())).thenAnswer((_) async {});
        return TodoBloc(
          todoRepo: todoRepo,
          completionRepo: completionRepo,
          uuid: uuid,
          notifications: scheduler,
          now: () => DateTime(2026, 6, 26),
        );
      },
      act: (b) => b.add(const TodoCompletionToggled('a1')),
      verify: (_) {
        final captured = verify(() => completionRepo.insert(captureAny())).captured.single
            as TodoCompletion;
        expect(captured.todoId, 'a1');
        expect(captured.id, 'fixed-uuid');
        expect(captured.periodStart, DateTime(2026, 6, 1));
        expect(captured.periodEnd, DateTime(2026, 6, 30, 23, 59, 59, 999));
      },
    );
  });

  group('Reminder scheduling', () {
    blocTest<TodoBloc, TodoState>(
      'schedules with recurrence when reminderTime is set on create',
      build: () {
        when(() => todoRepo.insert(any())).thenAnswer((_) async {});
        return TodoBloc(
          todoRepo: todoRepo,
          completionRepo: completionRepo,
          uuid: uuid,
          notifications: scheduler,
          now: () => DateTime(2026, 6, 1, 8),
        );
      },
      act: (b) => b.add(TodoCreated(
        title: 'rent',
        reminderTime: DateTime(2026, 6, 10, 9),
        recurrence: Recurrence.monthly,
      )),
      verify: (_) {
        verify(() => scheduler.schedule(
              'fixed-uuid',
              'rent',
              DateTime(2026, 6, 10, 9),
              recurrence: Recurrence.monthly,
            )).called(1);
      },
    );

    blocTest<TodoBloc, TodoState>(
      'does not schedule when reminderTime is null',
      build: () {
        when(() => todoRepo.insert(any())).thenAnswer((_) async {});
        return TodoBloc(
          todoRepo: todoRepo,
          completionRepo: completionRepo,
          uuid: uuid,
          notifications: scheduler,
        );
      },
      act: (b) => b.add(const TodoCreated(title: 'no reminder')),
      verify: (_) {
        verifyNever(() => scheduler.schedule(
              any(),
              any(),
              any(),
              recurrence: any(named: 'recurrence'),
            ));
      },
    );

    blocTest<TodoBloc, TodoState>(
      'schedules recurring todo even when reminderTime is in the past '
      '(next-occurrence fallback)',
      build: () {
        when(() => todoRepo.insert(any())).thenAnswer((_) async {});
        return TodoBloc(
          todoRepo: todoRepo,
          completionRepo: completionRepo,
          uuid: uuid,
          notifications: scheduler,
          now: () => DateTime(2026, 6, 17, 12),
        );
      },
      act: (b) => b.add(TodoCreated(
        title: 'weekly',
        reminderTime: DateTime(2026, 5, 20, 9), // past
        recurrence: Recurrence.weekly,
      )),
      verify: (_) {
        verify(() => scheduler.schedule(
              any(),
              any(),
              any(),
              recurrence: Recurrence.weekly,
            )).called(1);
      },
    );

    blocTest<TodoBloc, TodoState>(
      'does not schedule a one-time todo when reminderTime is in the past',
      build: () {
        when(() => todoRepo.insert(any())).thenAnswer((_) async {});
        return TodoBloc(
          todoRepo: todoRepo,
          completionRepo: completionRepo,
          uuid: uuid,
          notifications: scheduler,
          now: () => DateTime(2026, 6, 17, 12),
        );
      },
      act: (b) => b.add(TodoCreated(
        title: 'missed',
        reminderTime: DateTime(2026, 6, 1, 9), // past
        recurrence: Recurrence.none,
      )),
      verify: (_) {
        verifyNever(() => scheduler.schedule(
              any(),
              any(),
              any(),
              recurrence: any(named: 'recurrence'),
            ));
      },
    );

    blocTest<TodoBloc, TodoState>(
      'cancels the existing notification before rescheduling on update',
      build: () {
        when(() => todoRepo.update(any())).thenAnswer((_) async {});
        return TodoBloc(
          todoRepo: todoRepo,
          completionRepo: completionRepo,
          uuid: uuid,
          notifications: scheduler,
          now: () => DateTime(2026, 6, 1, 8),
        );
      },
      act: (b) => b.add(TodoUpdated(makeTodo().copyWith(
        reminderTime: DateTime(2026, 6, 15, 14),
      ))),
      verify: (_) {
        verifyInOrder([
          () => scheduler.cancel('a1'),
          () => scheduler.schedule(
                'a1',
                any(),
                DateTime(2026, 6, 15, 14),
                recurrence: Recurrence.monthly,
              ),
        ]);
      },
    );
  });
}
