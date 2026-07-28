import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/category.dart';

void main() {
  test('round-trips through toMap/fromMap', () {
    final c = Category(
      id: 'c1',
      title: 'Health',
      description: 'Body and mind',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
      archived: false,
    );
    expect(Category.fromMap(c.toMap()), equals(c));
  });

  test('copyWith preserves id and createdAt', () {
    final c = Category(
      id: 'c1', title: 't',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      archived: false,
    );
    final c2 = c.copyWith(title: 'T2', updatedAt: DateTime(2026, 2, 2));
    expect(c2.id, 'c1');
    expect(c2.title, 'T2');
    expect(c2.createdAt, DateTime(2026, 1, 1));
    expect(c2.updatedAt, DateTime(2026, 2, 2));
  });
}
