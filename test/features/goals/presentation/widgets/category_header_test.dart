import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/category.dart';
import 'package:todos/features/goals/presentation/widgets/category_header.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders category title and description', (tester) async {
    final cat = Category(
      id: 'c1', title: 'Health', description: 'body + mind',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      archived: false,
    );
    await tester.pumpWidget(host(CategoryHeader(
      category: cat, initiallyExpanded: true,
      onEdit: (_) {}, onDelete: (_) {},
    )));
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('body + mind'), findsOneWidget);
  });

  testWidgets('overflow menu exposes Edit and Delete', (tester) async {
    final cat = Category(
      id: 'c1', title: 'Health',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      archived: false,
    );
    var edited = 0, deleted = 0;
    await tester.pumpWidget(host(CategoryHeader(
      category: cat, initiallyExpanded: true,
      onEdit: (_) => edited++, onDelete: (_) => deleted++,
    )));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Category'));
    await tester.pumpAndSettle();
    expect(edited, 1);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Category'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
  });
}
