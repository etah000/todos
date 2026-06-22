import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/logs/data/log_item_repository.dart';
import 'package:todos/features/logs/domain/log_item.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  group('LogItemRepository', () {
    late AppDatabase db;
    late LogItemRepository repo;

    setUp(() async {
      db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
      repo = LogItemRepository(db);
    });
    tearDown(() async => db.close());

    test('insert + getAll excludes archived by default', () async {
      final now = DateTime.now();
      await repo.insert(LogItem(id: 'a', name: 'weight', createdAt: now, archived: false));
      await repo.insert(LogItem(id: 'b', name: 'mood', createdAt: now, archived: true));
      final all = await repo.getAll();
      expect(all.map((e) => e.id), ['a']);
      final allInclArchived = await repo.getAll(includeArchived: true);
      expect(allInclArchived.length, 2);
    });

    test('update mutates the row', () async {
      final now = DateTime.now();
      await repo.insert(LogItem(id: 'a', name: 'weight', createdAt: now, archived: false));
      await repo.update(LogItem(id: 'a', name: 'weight!', unit: 'kg', createdAt: now, archived: false));
      final got = (await repo.getAll()).single;
      expect(got.name, 'weight!');
      expect(got.unit, 'kg');
    });
  });
}