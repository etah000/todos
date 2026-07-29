import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/goals/data/category_repository.dart';
import 'package:todos/features/goals/data/goal_activity_repository.dart';
import 'package:todos/features/goals/data/goal_log_repository.dart';
import 'package:todos/features/goals/domain/category.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:todos/features/goals/presentation/bloc/goal_event.dart';
import 'package:todos/features/goals/presentation/bloc/goal_state.dart';
import 'package:todos/features/goals/presentation/pages/goal_form_page.dart';
import 'package:todos/features/todos/domain/recurrence.dart';
import 'package:uuid/uuid.dart';

class _StubBloc extends GoalBloc {
  _StubBloc(AppDatabase db) : super(
        categoryRepo: CategoryRepository(db),
        activityRepo: GoalActivityRepository(db),
        logRepo: GoalLogRepository(db),
        uuid: const Uuid(),
      );
  final dispatched = <GoalEvent>[];
  @override
  void add(GoalEvent event) {
    dispatched.add(event);
    // Don't propagate to the real handlers — they would try to mutate the DB
    // and cause noise. We only care that events are captured.
  }
  @override
  GoalState get state => GoalsLoaded(
        categories: [
          Category(
            id: 'c1',
            title: 'Health',
            createdAt: _epoch,
            updatedAt: _epoch,
            archived: false,
          ),
        ],
        activitiesByCategoryId: const {},
        logsByActivityId: const {},
      );
}

// A fixed DateTime used to satisfy Category's non-null createdAt/updatedAt
// fields without leaking into the assertions in these tests.
final DateTime _epoch = DateTime(2026, 1, 1);

// The form is long; the default 800x600 test surface clips the submit
// button behind the ListView's bottom edge. Resize the test view inside
// each test so the whole form is visible.
Future<void> _setTallViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase db;
  late _StubBloc bloc;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    bloc = _StubBloc(db);
  });
  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  testWidgets('Create mode: dispatching GoalActivityCreated with selected category', (tester) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: BlocProvider<GoalBloc>.value(
      value: bloc, child: const GoalFormPage(),
    )));
    await tester.enterText(find.byType(TextField).first, 'pushup');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    final ev = bloc.dispatched.whereType<GoalActivityCreated>().single;
    expect(ev.title, 'pushup');
    expect(ev.categoryId, 'c1');
  });

  testWidgets('Edit mode: prefills and dispatches GoalActivityUpdated', (tester) async {
    await _setTallViewport(tester);
    final existing = GoalActivity(
      id: 'a1', categoryId: 'c1', title: 'pushup',
      recurrence: Recurrence.daily,
      startDate: DateTime(2026, 7, 1),
      targetValue: 15, targetUnit: GoalTargetUnit.perDay,
      metric: ActivityMetric.count,
      createdAt: DateTime(2026, 7, 1),
    );
    await tester.pumpWidget(MaterialApp(home: BlocProvider<GoalBloc>.value(
      value: bloc, child: GoalFormPage(existing: existing),
    )));
    expect(find.text('pushup'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'meditate');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    final ev = bloc.dispatched.whereType<GoalActivityUpdated>().single;
    expect(ev.activity.title, 'meditate');
  });
}
