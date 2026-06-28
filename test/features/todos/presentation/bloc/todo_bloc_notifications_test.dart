import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todos/features/todos/data/todo_completion_repository.dart';
import 'package:todos/features/todos/data/todo_repository.dart';
import 'package:todos/features/todos/domain/recurrence.dart';
import 'package:todos/features/todos/domain/todo.dart';
import 'package:todos/features/todos/presentation/bloc/notification_scheduler.dart';
import 'package:todos/features/todos/presentation/bloc/todo_bloc.dart';
import 'package:todos/features/todos/presentation/bloc/todo_event.dart';
import 'package:uuid/uuid.dart';

class _MockTodoRepo extends Mock implements TodoRepository {}
class _MockCompletionRepo extends Mock implements TodoCompletionRepository {}
class _MockScheduler extends Mock implements NotificationScheduler {}

void main() {
  late _MockTodoRepo todoRepo;
  late _MockCompletionRepo completionRepo;
  late _MockScheduler scheduler;

  setUpAll(() {
    registerFallbackValue(Recurrence.none);
    registerFallbackValue(Todo(
      id: 'fb', title: 'fb', createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1), archived: false, recurrence: Recurrence.none,
    ));
  });

  setUp(() {
    todoRepo = _MockTodoRepo();
    completionRepo = _MockCompletionRepo();
    scheduler = _MockScheduler();
    when(() => todoRepo.insert(any())).thenAnswer((_) async {});
    when(() => todoRepo.getAll()).thenAnswer((_) async => []);
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

  blocTest<TodoBloc, dynamic>(
    'schedules a notification when reminderTime is in the future',
    build: () => TodoBloc(
      todoRepo: todoRepo,
      completionRepo: completionRepo,
      uuid: const Uuid(),
      notifications: scheduler,
      now: () => DateTime(2026, 6, 1),
    ),
    act: (b) => b.add(TodoCreated(
      title: 'rent',
      reminderTime: DateTime(2026, 6, 10, 9),
    )),
    verify: (_) {
      verify(() => scheduler.schedule(any(), 'rent', DateTime(2026, 6, 10, 9))).called(1);
    },
  );

  blocTest<TodoBloc, dynamic>(
    'does not schedule when reminderTime is null or in the past',
    build: () => TodoBloc(
      todoRepo: todoRepo,
      completionRepo: completionRepo,
      uuid: const Uuid(),
      notifications: scheduler,
      now: () => DateTime(2026, 6, 1),
    ),
    act: (b) => b.add(TodoCreated(title: 'rent')),
    verify: (_) {
      verifyNever(() => scheduler.schedule(any(), any(), any()));
    },
  );
}
