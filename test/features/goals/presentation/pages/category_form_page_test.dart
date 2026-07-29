import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/goals/data/category_repository.dart';
import 'package:todos/features/goals/data/goal_activity_repository.dart';
import 'package:todos/features/goals/data/goal_log_repository.dart';
import 'package:todos/features/goals/domain/category.dart';
import 'package:todos/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:todos/features/goals/presentation/bloc/goal_event.dart';
import 'package:todos/features/goals/presentation/pages/category_form_page.dart';
import 'package:uuid/uuid.dart';

class _RecordingBloc extends GoalBloc {
  _RecordingBloc(AppDatabase db) : super(
        categoryRepo: CategoryRepository(db),
        activityRepo: GoalActivityRepository(db),
        logRepo: GoalLogRepository(db),
        uuid: const Uuid(),
      );
  final dispatched = <GoalEvent>[];
  @override
  void add(GoalEvent event) {
    dispatched.add(event);
    // Don't propagate to the real handlers — they would try to query the DB
    // and cause noise in the test. We only care that events are captured.
  }
}

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase db;
  late _RecordingBloc bloc;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    bloc = _RecordingBloc(db);
  });
  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  testWidgets('Create mode: empty title blocks submit', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BlocProvider<GoalBloc>.value(
      value: bloc, child: const CategoryFormPage(),
    )));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(bloc.dispatched, isEmpty);
  });

  testWidgets('Create mode: dispatching CategoryCreated on submit', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BlocProvider<GoalBloc>.value(
      value: bloc, child: const CategoryFormPage(),
    )));
    await tester.enterText(find.byType(TextField).first, 'Health');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(bloc.dispatched.whereType<CategoryCreated>(), hasLength(1));
  });

  testWidgets('Edit mode: prefills title and dispatches CategoryUpdated', (tester) async {
    final existing = Category(
      id: 'c1', title: 'Health', description: 'old',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      archived: false,
    );
    await tester.pumpWidget(MaterialApp(home: BlocProvider<GoalBloc>.value(
      value: bloc, child: CategoryFormPage(existing: existing),
    )));
    expect(find.text('Health'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Wellness');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    final updated = bloc.dispatched.whereType<CategoryUpdated>().single;
    expect(updated.category.title, 'Wellness');
    expect(updated.category.id, 'c1');
  });
}