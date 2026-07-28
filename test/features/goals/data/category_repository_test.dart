import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/goals/data/category_repository.dart';
import 'package:todos/features/goals/domain/category.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase db;
  late CategoryRepository repo;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    repo = CategoryRepository(db);
  });
  tearDown(() async => db.close());

  Category makeCategory(String id, {String title = 'Health'}) => Category(
        id: id, title: title,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        archived: false,
      );

  test('insert + getById round-trip', () async {
    final c = makeCategory('c1');
    await repo.insert(c);
    expect(await repo.getById('c1'), equals(c));
  });

  test('getAll returns only non-archived by default', () async {
    await repo.insert(makeCategory('c1', title: 'A'));
    await repo.insert(makeCategory('c2', title: 'B').copyWith(archived: true));
    final all = await repo.getAll();
    expect(all.map((c) => c.id), ['c1']);
  });

  test('update persists changes', () async {
    await repo.insert(makeCategory('c1'));
    await repo.update(makeCategory('c1', title: 'New'));
    expect((await repo.getById('c1'))!.title, 'New');
  });

  test('delete removes the row', () async {
    await repo.insert(makeCategory('c1'));
    await repo.delete('c1');
    expect(await repo.getById('c1'), isNull);
  });
}
