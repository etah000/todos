import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/countdown/data/countdown_repository.dart';
import 'package:todos/features/countdown/domain/countdown_event.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  group('CountdownRepository', () {
    late AppDatabase db;
    late CountdownRepository repo;

    setUp(() async {
      db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
      repo = CountdownRepository(db);
    });
    tearDown(() async => db.close());

    test('insert + getAll returns non-archived, ordered by target date', () async {
      final now = DateTime.now();
      await repo.insert(CountdownEvent(
        id: 'b', title: 'Later', targetDate: DateTime(2027, 1, 1),
        createdAt: now, archived: false,
      ));
      await repo.insert(CountdownEvent(
        id: 'a', title: 'Sooner', targetDate: DateTime(2026, 7, 1),
        createdAt: now, archived: false,
      ));
      await repo.insert(CountdownEvent(
        id: 'c', title: 'Old', targetDate: DateTime(2025, 1, 1),
        createdAt: now, archived: true,
      ));
      final all = await repo.getAll();
      expect(all.map((e) => e.id), ['a', 'b']);
    });
  });
}