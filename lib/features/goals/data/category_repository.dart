import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/category.dart';

class CategoryRepository {
  CategoryRepository(this._db);
  final AppDatabase _db;
  Database get _raw => _db.raw;

  Future<void> insert(Category c) => _raw.insert(Tables.categories, c.toMap());

  Future<Category?> getById(String id) async {
    final rows = await _raw.query(
      Tables.categories,
      where: '${CategoryCols.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<List<Category>> getAll({bool includeArchived = false}) async {
    final rows = await _raw.query(
      Tables.categories,
      where: includeArchived ? null : '${CategoryCols.archived} = 0',
      orderBy: '${CategoryCols.createdAt} ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<void> update(Category c) => _raw.update(
        Tables.categories,
        c.toMap(),
        where: '${CategoryCols.id} = ?',
        whereArgs: [c.id],
      );

  Future<void> delete(String id) => _raw.delete(
        Tables.categories,
        where: '${CategoryCols.id} = ?',
        whereArgs: [id],
      );
}
