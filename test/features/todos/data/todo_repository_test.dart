// test/features/todos/data/todo_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/todos/data/todo_repository.dart';
import 'package:todos/features/todos/domain/recurrence.dart';
import 'package:todos/features/todos/domain/todo.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  group('TodoRepository', () {
    late AppDatabase db;
    late TodoRepository repo;

    setUp(() async {
      db = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      repo = TodoRepository(db);
    });
    tearDown(() async => db.close());

    Todo makeTodo({
      String id = 'a1',
      String title = 'rent',
      Recurrence recurrence = Recurrence.monthly,
    }) {
      final now = DateTime.now();
      return Todo(
        id: id,
        title: title,
        recurrence: recurrence,
        createdAt: now,
        updatedAt: now,
        archived: false,
      );
    }

    test('insert + getById', () async {
      await repo.insert(makeTodo());
      final t = await repo.getById('a1');
      expect(t, isNotNull);
      expect(t!.title, 'rent');
      expect(t.recurrence, Recurrence.monthly);
    });

    test('getAll returns non-archived first, then archived', () async {
      final now = DateTime.now();
      await repo.insert(makeTodo(id: 'a', title: 'A'));
      await repo.insert(makeTodo(id: 'b', title: 'B'));
      await repo.update(
        makeTodo(id: 'a', title: 'A').copyWith(archived: true, updatedAt: now),
      );
      final all = await repo.getAll();
      expect(all.map((t) => t.id).toList(), ['b', 'a']);
    });

    test('update mutates the row', () async {
      await repo.insert(makeTodo());
      await repo.update(makeTodo().copyWith(title: 'rent!', updatedAt: DateTime.now()));
      final t = await repo.getById('a1');
      expect(t!.title, 'rent!');
    });

    test('delete removes the row and cascades to completions', () async {
      await repo.insert(makeTodo());
      // Add a completion through raw SQL (repo lives in a sibling task).
      final raw = db.raw;
      final now = DateTime.now().millisecondsSinceEpoch;
      await raw.insert('todo_completions', {
        'id': 'c1', 'todo_id': 'a1', 'period_start': now, 'period_end': now, 'completed_at': now,
      });
      await repo.delete('a1');
      final t = await repo.getById('a1');
      expect(t, isNull);
      final remaining = await raw.query('todo_completions', where: 'todo_id = ?', whereArgs: ['a1']);
      expect(remaining, isEmpty);
    });
  });
}
