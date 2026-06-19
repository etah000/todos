// test/features/todos/data/todo_completion_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/todos/data/todo_completion_repository.dart';
import 'package:todos/features/todos/data/todo_repository.dart';
import 'package:todos/features/todos/domain/recurrence.dart';
import 'package:todos/features/todos/domain/todo.dart';
import 'package:todos/features/todos/domain/todo_completion.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  group('TodoCompletionRepository', () {
    late AppDatabase db;
    late TodoCompletionRepository repo;
    late TodoRepository todos;

    setUp(() async {
      db = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      todos = TodoRepository(db);
      repo = TodoCompletionRepository(db);
      final now = DateTime.now();
      await todos.insert(Todo(
        id: 'a1', title: 'rent', recurrence: Recurrence.monthly,
        createdAt: now, updatedAt: now, archived: false,
      ));
    });
    tearDown(() async => db.close());

    test('insert + listByTodo', () async {
      final c = TodoCompletion(
        id: 'c1', todoId: 'a1',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 30, 23, 59, 59, 999),
        completedAt: DateTime(2026, 6, 26),
      );
      await repo.insert(c);
      final list = await repo.listByTodo('a1');
      expect(list, [c]);
    });

    test('findByTodoInPeriod returns the completion for that period', () async {
      final c = TodoCompletion(
        id: 'c1', todoId: 'a1',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 30, 23, 59, 59, 999),
        completedAt: DateTime(2026, 6, 26),
      );
      await repo.insert(c);
      final found = await repo.findByTodoInPeriod(
        'a1',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 30, 23, 59, 59, 999),
      );
      expect(found, c);
    });

    test('findByTodoInPeriod returns null when no completion', () async {
      final found = await repo.findByTodoInPeriod(
        'a1',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 30, 23, 59, 59, 999),
      );
      expect(found, isNull);
    });
  });
}
