import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/logs/data/log_entry_repository.dart';
import 'package:todos/features/logs/data/log_item_repository.dart';
import 'package:todos/features/logs/domain/log_entry.dart';
import 'package:todos/features/logs/domain/log_item.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  group('LogEntryRepository', () {
    late AppDatabase db;
    late LogEntryRepository entries;
    late LogItemRepository items;

    setUp(() async {
      db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
      items = LogItemRepository(db);
      entries = LogEntryRepository(db);
      final now = DateTime.now();
      await items.insert(LogItem(id: 'i1', name: 'weight', createdAt: now, archived: false));
    });
    tearDown(() async => db.close());

    test('insert + listByItemInRange is ordered by loggedAt DESC', () async {
      await entries.insert(LogEntry(id: 'a', logItemId: 'i1', value: 80, loggedAt: DateTime(2026, 6, 1), createdAt: DateTime(2026, 6, 1)));
      await entries.insert(LogEntry(id: 'b', logItemId: 'i1', value: 81, loggedAt: DateTime(2026, 6, 10), createdAt: DateTime(2026, 6, 10)));
      await entries.insert(LogEntry(id: 'c', logItemId: 'i1', value: 79, loggedAt: DateTime(2026, 5, 20), createdAt: DateTime(2026, 5, 20)));
      final got = await entries.listByItemInRange(
        'i1',
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 6, 30, 23, 59, 59, 999),
      );
      expect(got.map((e) => e.id), ['b', 'a', 'c']);
    });

    test('listByItemInRange respects bounds', () async {
      await entries.insert(LogEntry(id: 'a', logItemId: 'i1', value: 80, loggedAt: DateTime(2026, 6, 1), createdAt: DateTime(2026, 6, 1)));
      await entries.insert(LogEntry(id: 'b', logItemId: 'i1', value: 81, loggedAt: DateTime(2026, 7, 1), createdAt: DateTime(2026, 7, 1)));
      final got = await entries.listByItemInRange(
        'i1',
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 6, 30, 23, 59, 59, 999),
      );
      expect(got.map((e) => e.id), ['a']);
    });

    test('delete cascades via foreign key', () async {
      await entries.insert(LogEntry(id: 'a', logItemId: 'i1', value: 80, loggedAt: DateTime(2026, 6, 1), createdAt: DateTime(2026, 6, 1)));
      await items.delete('i1');
      final got = await entries.listByItemInRange('i1', from: DateTime(2020), to: DateTime(2030));
      expect(got, isEmpty);
    });
  });
}