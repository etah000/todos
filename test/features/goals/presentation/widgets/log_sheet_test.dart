import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal_log.dart';
import 'package:todos/features/goals/presentation/widgets/log_sheet.dart';

void main() {
  testWidgets('Add mode: pops a new GoalLog with the entered value', (tester) async {
    GoalLog? result;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) => Scaffold(
      body: ElevatedButton(
        onPressed: () async {
          result = await showLogSheet(context: ctx, goalActivityId: 'a1');
        },
        child: const Text('open'),
      ),
    ))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '5');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.value, 5.0);
    expect(result!.goalActivityId, 'a1');
  });

  testWidgets('Edit mode: prefills value and notes', (tester) async {
    final existing = GoalLog(
      id: 'l1', goalActivityId: 'a1', value: 7,
      notes: 'felt great',
      loggedAt: DateTime(2026, 7, 1),
      createdAt: DateTime(2026, 7, 1),
    );
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) => Scaffold(
      body: ElevatedButton(
        onPressed: () async {
          await showLogSheet(context: ctx, goalActivityId: 'a1', existing: existing);
        },
        child: const Text('open'),
      ),
    ))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);
    expect(find.text('felt great'), findsOneWidget);
  });
}
