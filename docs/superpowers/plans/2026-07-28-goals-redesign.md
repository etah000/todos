# Goals Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current single-level Goals tab with a two-level model: free-standing **Categories** contain one or more **Goals** with their own start date, target expression, and per-event log. All CRUD on both levels. Clean-slate migration from v3.

**Architecture:** New schema (v4) drops the old `goals`, `goal_activities`, `activity_completions` tables and adds `categories`, an extended `goal_activities`, and `goal_logs`. `GoalBloc` keeps its name but is rewritten to handle Category CRUD + GoalActivity CRUD + GoalLog events. UI replaces the existing `GoalListPage`/`GoalDetailPage` with a tree view (default-expanded Categories, Goals clickable to a detail page) and a new `GoalDetailPage` for per-Goal logs.

**Tech Stack:** Flutter, flutter_bloc, sqflite/sqflite_common_ffi, equatable, flutter_test, bloc_test, mocktail.

## Global Constraints

- Keep feature code under `lib/features/goals/`.
- Keep tests mirrored under `test/features/goals/`.
- Use existing BLoC, repository, database, and routing patterns.
- Bump `Migrations.currentVersion` to `4`. The `onUpgrade` for v3→v4 must drop the old tables and create the new ones in a single transaction (the user explicitly chose clean slate — no data preservation).
- Use TDD: write a failing focused test before production code for each behavior change.
- Reuse the confirmation-dialog pattern from the Logs and Countdown delete buttons for every destructive action.
- Reuse `Recurrence` (from `lib/features/todos/domain/recurrence.dart`) and `PeriodCalculator` (from `lib/core/utils/period_calculator.dart`).
- Reuse `EmptyState` (from `lib/core/widgets/empty_state.dart`).

---

## File Structure

### New files

- `lib/features/goals/domain/category.dart`
- `lib/features/goals/domain/goal_log.dart`
- `lib/features/goals/domain/goal_target_unit.dart`
- `lib/features/goals/domain/goal_progress_snapshot.dart`
- `lib/features/goals/data/category_repository.dart`
- `lib/features/goals/data/goal_log_repository.dart`
- `lib/features/goals/presentation/pages/category_form_page.dart`
- `lib/features/goals/presentation/widgets/category_header.dart`
- `lib/features/goals/presentation/widgets/goal_tile.dart`
- `lib/features/goals/presentation/widgets/log_sheet.dart`
- Tests mirroring each new file under `test/features/goals/`.

### Modified files

- `lib/core/database/schema.dart`
- `lib/core/database/migrations.dart`
- `lib/features/goals/domain/goal_activity.dart`
- `lib/features/goals/data/goal_activity_repository.dart`
- `lib/features/goals/presentation/bloc/goal_event.dart`
- `lib/features/goals/presentation/bloc/goal_state.dart`
- `lib/features/goals/presentation/bloc/goal_bloc.dart`
- `lib/features/goals/presentation/pages/goal_list_page.dart`
- `lib/features/goals/presentation/pages/goal_form_page.dart`
- `lib/features/goals/presentation/pages/goal_detail_page.dart`

### Deleted files

- `lib/features/goals/domain/goal.dart`
- `lib/features/goals/domain/activity_completion.dart`
- `lib/features/goals/data/goal_repository.dart`
- `lib/features/goals/data/activity_completion_repository.dart`
- `lib/features/goals/presentation/pages/activity_form_page.dart`
- `lib/features/goals/presentation/widgets/activity_tile.dart`
- `test/features/goals/domain/goal_test.dart`
- `test/features/goals/data/repositories_test.dart`

---

### Task 1: Schema migration v4

**Files:**
- Modify: `lib/core/database/schema.dart`
- Modify: `lib/core/database/migrations.dart`
- Create: `test/core/database/migrations_test.dart`

**Interfaces:**
- Consumes: existing `Migrations.currentVersion`, existing `Tables`/`*Cols` classes
- Produces: `Tables.categories`, `Tables.goalLogs`, `CategoryCols`, `GoalLogCols`, updated `GoalActivityCols` (`categoryId` instead of `goalId`, plus `startDate`, `targetValue`, `targetUnit`), `Migrations.currentVersion = 4`, and an `onUpgrade` v3→v4 block that drops `activity_completions`, `goal_activities`, `goals` and creates the three new tables.

- [ ] **Step 1: Write the failing test**

Create `test/core/database/migrations_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/core/database/migrations.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  test('onUpgrade v3→v4 creates new tables and drops the old', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (d, _) async {
          await d.execute(
            'CREATE TABLE goals (id TEXT PRIMARY KEY, title TEXT, start_date INTEGER, end_date INTEGER, created_at INTEGER, updated_at INTEGER, archived INTEGER)',
          );
          await d.execute(
            'CREATE TABLE goal_activities (id TEXT PRIMARY KEY, goal_id TEXT, title TEXT, recurrence_type TEXT, created_at INTEGER)',
          );
          await d.execute(
            'CREATE TABLE activity_completions (id TEXT PRIMARY KEY, activity_id TEXT, period_start INTEGER, period_end INTEGER, completed_at INTEGER)',
          );
        },
        onUpgrade: Migrations.onUpgrade,
      ),
    );

    await db.setVersion(4);
    await Migrations.onUpgrade(db, 3, 4);

    final names = (await db.query('sqlite_master', columns: ['name']))
        .map((r) => r['name'] as String)
        .toSet();
    expect(names.contains('categories'), isTrue);
    expect(names.contains('goal_activities'), isTrue);
    expect(names.contains('goal_logs'), isTrue);
    expect(names.contains('activity_completions'), isFalse);
    expect(names.contains('goals'), isFalse);
    await db.close();
  });

  test('currentVersion is 4', () {
    expect(Migrations.currentVersion, 4);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/database/migrations_test.dart`

Expected: FAIL — `Migrations.currentVersion` is `3`, no new tables.

- [ ] **Step 3: Update schema constants**

In `lib/core/database/schema.dart`:

- Add to `Tables`: `static const categories = 'categories';` and `static const goalLogs = 'goal_logs';`
- Add `CategoryCols` class with `id`, `title`, `description`, `createdAt`, `updatedAt`, `archived`.
- Add `GoalLogCols` class with `id`, `goalActivityId`, `value`, `notes`, `loggedAt`, `createdAt`.
- Replace `GoalActivityCols`: drop `goalId`, `totalCount`, `totalSeconds`; add `categoryId`, `startDate`, `targetValue`, `targetUnit`. Keep `id`, `title`, `recurrenceType`, `recurrenceConfig`, `metric`, `createdAt`.

- [ ] **Step 4: Update migrations**

In `lib/core/database/migrations.dart`:

- Set `static const int currentVersion = 4;`
- In `onCreate`, drop the existing `goals`, `goal_activities`, `activity_completions` blocks. Add three new `batch.execute` blocks: `categories`, `goal_activities` (with `FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE`), `goal_logs` (with `FOREIGN KEY (goal_activity_id) REFERENCES goal_activities(id) ON DELETE CASCADE`). Add indexes `idx_goal_activities_category` and `idx_goal_logs_activity`.
- In `onUpgrade`, remove the v2 block that alters `goal_activities` to add `metric`/`total_count`/`total_seconds` (the table is now created fresh at v4). Keep the `finished_todos` portion of v2 and the v3 `todos.reminder_mode` migration.
- Add a `v3→v4` block at the end of `onUpgrade` that drops `activity_completions`, `goal_activities`, `goals` and creates the three new tables.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/database/migrations_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/database/schema.dart lib/core/database/migrations.dart test/core/database/migrations_test.dart
git commit -m "feat(goals): schema migration v4 — categories + goals + goal_logs"
```

---

### Task 2: `Category` domain + repository

**Files:**
- Create: `lib/features/goals/domain/category.dart`
- Create: `lib/features/goals/data/category_repository.dart`
- Create: `test/features/goals/domain/category_test.dart`
- Create: `test/features/goals/data/category_repository_test.dart`
- Delete: `lib/features/goals/domain/goal.dart`, `lib/features/goals/data/goal_repository.dart`, `test/features/goals/domain/goal_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `Tables.categories`, `CategoryCols`, `equatable`
- Produces: `class Category extends Equatable` with fields `id`, `title`, `description?`, `createdAt`, `updatedAt`, `archived`; methods `copyWith`, `toMap`, `fromMap`, `Equatable.props`. `class CategoryRepository` with `insert`, `getById`, `getAll({includeArchived = false})`, `update`, `delete`.

- [ ] **Step 1: Write failing tests for `Category`**

Create `test/features/goals/domain/category_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/goals/domain/category_test.dart`

Expected: FAIL — `Category` not defined.

- [ ] **Step 3: Implement `Category`**

Create `lib/features/goals/domain/category.dart`:

```dart
import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;

  Category copyWith({
    String? title,
    String? description,
    DateTime? updatedAt,
    bool? archived,
  }) =>
      Category(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        archived: archived ?? this.archived,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'archived': archived ? 1 : 0,
      };

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
        archived: (m['archived'] as int) == 1,
      );

  @override
  List<Object?> get props => [id, title, description, createdAt, updatedAt, archived];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/goals/domain/category_test.dart`

Expected: PASS.

- [ ] **Step 5: Write failing tests for `CategoryRepository`**

Create `test/features/goals/data/category_repository_test.dart`:

```dart
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
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/features/goals/data/category_repository_test.dart`

Expected: FAIL — `CategoryRepository` not defined.

- [ ] **Step 7: Implement `CategoryRepository`**

Create `lib/features/goals/data/category_repository.dart`:

```dart
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
```

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/features/goals/data/category_repository_test.dart`

Expected: PASS.

- [ ] **Step 9: Delete obsolete files**

```bash
git rm lib/features/goals/domain/goal.dart \
       lib/features/goals/data/goal_repository.dart \
       test/features/goals/domain/goal_test.dart
```

- [ ] **Step 10: Commit**

```bash
git add lib/features/goals/domain/category.dart lib/features/goals/data/category_repository.dart \
        test/features/goals/domain/category_test.dart test/features/goals/data/category_repository_test.dart
git commit -m "feat(goals): add Category domain + repository"
```

---

### Task 3: `GoalLog` domain + repository

**Files:**
- Create: `lib/features/goals/domain/goal_log.dart`
- Create: `lib/features/goals/data/goal_log_repository.dart`
- Create: `test/features/goals/domain/goal_log_test.dart`
- Create: `test/features/goals/data/goal_log_repository_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `Tables.goalLogs`, `GoalLogCols`, `equatable`
- Produces: `class GoalLog extends Equatable` with `id`, `goalActivityId`, `value`, `notes?`, `loggedAt`, `createdAt`; methods `copyWith`, `toMap`, `fromMap`, `Equatable.props`. `class GoalLogRepository` with `insert`, `getById`, `listByActivity`, `listByActivityInRange`, `update`, `delete`.

- [ ] **Step 1: Write failing tests for `GoalLog`**

Create `test/features/goals/domain/goal_log_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal_log.dart';

void main() {
  test('round-trips through toMap/fromMap', () {
    final l = GoalLog(
      id: 'l1', goalActivityId: 'a1', value: 15.0, notes: 'felt good',
      loggedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      createdAt: DateTime.fromMillisecondsSinceEpoch(2000),
    );
    expect(GoalLog.fromMap(l.toMap()), equals(l));
  });

  test('notes is optional', () {
    final l = GoalLog(
      id: 'l1', goalActivityId: 'a1', value: 1.0,
      loggedAt: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    );
    expect(l.notes, isNull);
  });

  test('copyWith updates only the named fields', () {
    final l = GoalLog(
      id: 'l1', goalActivityId: 'a1', value: 1.0,
      loggedAt: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    );
    final l2 = l.copyWith(value: 2.0);
    expect(l2.id, 'l1');
    expect(l2.value, 2.0);
    expect(l2.loggedAt, DateTime(2026, 1, 1));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/goals/domain/goal_log_test.dart`

Expected: FAIL — `GoalLog` not defined.

- [ ] **Step 3: Implement `GoalLog`**

Create `lib/features/goals/domain/goal_log.dart`:

```dart
import 'package:equatable/equatable.dart';

class GoalLog extends Equatable {
  const GoalLog({
    required this.id,
    required this.goalActivityId,
    required this.value,
    required this.loggedAt,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String goalActivityId;
  final double value;
  final String? notes;
  final DateTime loggedAt;
  final DateTime createdAt;

  GoalLog copyWith({double? value, String? notes, DateTime? loggedAt}) =>
      GoalLog(
        id: id,
        goalActivityId: goalActivityId,
        value: value ?? this.value,
        notes: notes ?? this.notes,
        loggedAt: loggedAt ?? this.loggedAt,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'goal_activity_id': goalActivityId,
        'value': value,
        'notes': notes,
        'logged_at': loggedAt.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory GoalLog.fromMap(Map<String, Object?> m) => GoalLog(
        id: m['id'] as String,
        goalActivityId: m['goal_activity_id'] as String,
        value: (m['value'] as num).toDouble(),
        notes: m['notes'] as String?,
        loggedAt: DateTime.fromMillisecondsSinceEpoch(m['logged_at'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  @override
  List<Object?> get props => [id, goalActivityId, value, notes, loggedAt, createdAt];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/goals/domain/goal_log_test.dart`

Expected: PASS.

- [ ] **Step 5: Write failing tests for `GoalLogRepository`**

Create `test/features/goals/data/goal_log_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/goals/data/goal_log_repository.dart';
import 'package:todos/features/goals/domain/goal_log.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase db;
  late GoalLogRepository repo;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    repo = GoalLogRepository(db);
  });
  tearDown(() async => db.close());

  GoalLog makeLog(String id, String activityId, {DateTime? loggedAt, double value = 1.0}) =>
      GoalLog(
        id: id, goalActivityId: activityId, value: value,
        loggedAt: loggedAt ?? DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );

  test('insert + getById round-trip', () async {
    await repo.insert(makeLog('l1', 'a1'));
    expect((await repo.getById('l1'))!.id, 'l1');
  });

  test('listByActivity returns logs in descending loggedAt order', () async {
    await repo.insert(makeLog('l1', 'a1', loggedAt: DateTime(2026, 1, 1)));
    await repo.insert(makeLog('l2', 'a1', loggedAt: DateTime(2026, 1, 3)));
    await repo.insert(makeLog('l3', 'a2', loggedAt: DateTime(2026, 1, 2)));
    final logs = await repo.listByActivity('a1');
    expect(logs.map((l) => l.id), ['l2', 'l1']);
  });

  test('listByActivityInRange filters by loggedAt', () async {
    await repo.insert(makeLog('l1', 'a1', loggedAt: DateTime(2026, 1, 1)));
    await repo.insert(makeLog('l2', 'a1', loggedAt: DateTime(2026, 1, 10)));
    final logs = await repo.listByActivityInRange(
      'a1', from: DateTime(2026, 1, 5), to: DateTime(2026, 1, 31));
    expect(logs.map((l) => l.id), ['l2']);
  });

  test('update persists changes', () async {
    await repo.insert(makeLog('l1', 'a1'));
    await repo.update(makeLog('l1', 'a1').copyWith(value: 5.0));
    expect((await repo.getById('l1'))!.value, 5.0);
  });

  test('delete removes the row', () async {
    await repo.insert(makeLog('l1', 'a1'));
    await repo.delete('l1');
    expect(await repo.getById('l1'), isNull);
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/features/goals/data/goal_log_repository_test.dart`

Expected: FAIL — `GoalLogRepository` not defined.

- [ ] **Step 7: Implement `GoalLogRepository`**

Create `lib/features/goals/data/goal_log_repository.dart`:

```dart
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/goal_log.dart';

class GoalLogRepository {
  GoalLogRepository(this._db);
  final AppDatabase _db;
  Database get _raw => _db.raw;

  Future<void> insert(GoalLog l) => _raw.insert(Tables.goalLogs, l.toMap());

  Future<GoalLog?> getById(String id) async {
    final rows = await _raw.query(
      Tables.goalLogs,
      where: '${GoalLogCols.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GoalLog.fromMap(rows.first);
  }

  Future<List<GoalLog>> listByActivity(String activityId) async {
    final rows = await _raw.query(
      Tables.goalLogs,
      where: '${GoalLogCols.goalActivityId} = ?',
      whereArgs: [activityId],
      orderBy: '${GoalLogCols.loggedAt} DESC',
    );
    return rows.map(GoalLog.fromMap).toList();
  }

  Future<List<GoalLog>> listByActivityInRange(
    String activityId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _raw.query(
      Tables.goalLogs,
      where: '${GoalLogCols.goalActivityId} = ? '
          'AND ${GoalLogCols.loggedAt} >= ? '
          'AND ${GoalLogCols.loggedAt} <= ?',
      whereArgs: [
        activityId,
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch,
      ],
      orderBy: '${GoalLogCols.loggedAt} DESC',
    );
    return rows.map(GoalLog.fromMap).toList();
  }

  Future<void> update(GoalLog l) => _raw.update(
        Tables.goalLogs,
        l.toMap(),
        where: '${GoalLogCols.id} = ?',
        whereArgs: [l.id],
      );

  Future<void> delete(String id) => _raw.delete(
        Tables.goalLogs,
        where: '${GoalLogCols.id} = ?',
        whereArgs: [id],
      );
}
```

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/features/goals/data/goal_log_repository_test.dart`

Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/features/goals/domain/goal_log.dart lib/features/goals/data/goal_log_repository.dart \
        test/features/goals/domain/goal_log_test.dart test/features/goals/data/goal_log_repository_test.dart
git commit -m "feat(goals): add GoalLog domain + repository"
```

---

### Task 4: `GoalTargetUnit` enum

**Files:**
- Create: `lib/features/goals/domain/goal_target_unit.dart`
- Create: `test/features/goals/domain/goal_target_unit_test.dart`

**Interfaces:**
- Produces: `enum GoalTargetUnit { perDay, perWeek, perMonth, perPeriod }` with `wire` strings `"per_day"`, `"per_week"`, `"per_month"`, `"per_period"` and `static GoalTargetUnit parse(String? wire)` (default `perPeriod`).

- [ ] **Step 1: Write failing tests**

Create `test/features/goals/domain/goal_target_unit_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';

void main() {
  test('wire strings round-trip through parse', () {
    for (final u in GoalTargetUnit.values) {
      expect(GoalTargetUnit.parse(u.wire), equals(u));
    }
  });

  test('unknown wire defaults to perPeriod', () {
    expect(GoalTargetUnit.parse('garbage'), GoalTargetUnit.perPeriod);
  });

  test('null wire defaults to perPeriod', () {
    expect(GoalTargetUnit.parse(null), GoalTargetUnit.perPeriod);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/goals/domain/goal_target_unit_test.dart`

Expected: FAIL — `GoalTargetUnit` not defined.

- [ ] **Step 3: Implement the enum**

Create `lib/features/goals/domain/goal_target_unit.dart`:

```dart
enum GoalTargetUnit {
  perDay('per_day'),
  perWeek('per_week'),
  perMonth('per_month'),
  perPeriod('per_period');

  const GoalTargetUnit(this.wire);
  final String wire;

  static GoalTargetUnit parse(String? wire) {
    for (final u in GoalTargetUnit.values) {
      if (u.wire == wire) return u;
    }
    return GoalTargetUnit.perPeriod;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/goals/domain/goal_target_unit_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/goals/domain/goal_target_unit.dart test/features/goals/domain/goal_target_unit_test.dart
git commit -m "feat(goals): add GoalTargetUnit enum"
```

---

### Task 5: Extend `GoalActivity` domain + repository

**Files:**
- Modify: `lib/features/goals/domain/goal_activity.dart`
- Modify: `lib/features/goals/data/goal_activity_repository.dart`
- Create: `lib/features/goals/domain/goal_progress_snapshot.dart` (stub)
- Create: `test/features/goals/data/goal_activity_repository_test.dart`
- Modify: `test/features/goals/domain/goal_activity_test.dart`
- Delete: `lib/features/goals/domain/activity_completion.dart`, `lib/features/goals/data/activity_completion_repository.dart`, `test/features/goals/data/repositories_test.dart`

**Interfaces:**
- Consumes: `GoalTargetUnit`, `Recurrence`, `GoalProgressSnapshot` (stub)
- Produces: `GoalActivity` new required fields `categoryId`, `startDate`, `targetValue`, `targetUnit`; removes `goalId`, `totalCount`, `totalSeconds`; adds transient `progressSnapshot` (nullable; not in `Equatable.props`, not in `toMap`). `GoalActivityRepository.listByCategory(String categoryId)` replaces `listByGoal`.

- [ ] **Step 1: Create the `GoalProgressSnapshot` stub**

Create `lib/features/goals/domain/goal_progress_snapshot.dart` (Task 6 will replace it):

```dart
class GoalProgressSnapshot {
  const GoalProgressSnapshot({
    required this.periodsElapsed,
    required this.periodsCompleted,
    required this.percent,
    required this.lifetimeTotal,
  });

  factory GoalProgressSnapshot.empty() => const GoalProgressSnapshot(
        periodsElapsed: 0,
        periodsCompleted: 0,
        percent: 0,
        lifetimeTotal: GoalLifetimeTotalBoolean(0),
      );

  final int periodsElapsed;
  final int periodsCompleted;
  final double percent;
  final GoalLifetimeTotal lifetimeTotal;
}

sealed class GoalLifetimeTotal {
  const GoalLifetimeTotal();
}

class GoalLifetimeTotalBoolean extends GoalLifetimeTotal {
  const GoalLifetimeTotalBoolean(this.count);
  final int count;
}

class GoalLifetimeTotalCount extends GoalLifetimeTotal {
  const GoalLifetimeTotalCount(this.total);
  final double total;
}

class GoalLifetimeTotalDuration extends GoalLifetimeTotal {
  const GoalLifetimeTotalDuration(this.totalSeconds);
  final int totalSeconds;
}
```

- [ ] **Step 2: Write failing tests for the extended `GoalActivity`**

Rewrite `test/features/goals/domain/goal_activity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_progress_snapshot.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/todos/domain/recurrence.dart';

void main() {
  GoalActivity make({
    String id = 'a1',
    String categoryId = 'c1',
    String title = 'pushup',
    Recurrence recurrence = Recurrence.daily,
    DateTime? startDate,
    double targetValue = 15,
    GoalTargetUnit targetUnit = GoalTargetUnit.perDay,
    ActivityMetric metric = ActivityMetric.count,
  }) =>
      GoalActivity(
        id: id,
        categoryId: categoryId,
        title: title,
        recurrence: recurrence,
        startDate: startDate ?? DateTime(2026, 1, 1),
        targetValue: targetValue,
        targetUnit: targetUnit,
        metric: metric,
        createdAt: DateTime(2026, 1, 1),
      );

  test('round-trips through toMap/fromMap', () {
    final a = make();
    expect(GoalActivity.fromMap(a.toMap()), equals(a));
  });

  test('fromMap reads target_value and target_unit from new columns', () {
    final a = make(targetValue: 90, targetUnit: GoalTargetUnit.perWeek);
    final restored = GoalActivity.fromMap(a.toMap());
    expect(restored.targetValue, 90);
    expect(restored.targetUnit, GoalTargetUnit.perWeek);
  });

  test('progressSnapshot is not persisted and not in Equatable.props', () {
    final a = make().copyWith(progressSnapshot: GoalProgressSnapshot.empty());
    final restored = GoalActivity.fromMap(a.toMap());
    expect(restored.progressSnapshot, isNull);
    expect(a, equals(make()));
  });

  test('copyWith updates only the named fields and preserves id/categoryId/createdAt', () {
    final a = make();
    final a2 = a.copyWith(title: 'meditate', targetValue: 20);
    expect(a2.id, 'a1');
    expect(a2.categoryId, 'c1');
    expect(a2.createdAt, DateTime(2026, 1, 1));
    expect(a2.title, 'meditate');
    expect(a2.targetValue, 20);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/goals/domain/goal_activity_test.dart`

Expected: FAIL — `GoalActivity` lacks `categoryId`, `startDate`, `targetValue`, `targetUnit`, `progressSnapshot`.

- [ ] **Step 4: Implement the extended `GoalActivity`**

Rewrite `lib/features/goals/domain/goal_activity.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../todos/domain/recurrence.dart';
import 'goal_progress_snapshot.dart';
import 'goal_target_unit.dart';

enum ActivityMetric {
  boolean('boolean'),
  count('count'),
  duration('duration');

  const ActivityMetric(this.wire);
  final String wire;

  static ActivityMetric parse(String? wire) {
    for (final m in ActivityMetric.values) {
      if (m.wire == wire) return m;
    }
    return ActivityMetric.boolean;
  }
}

class GoalActivity extends Equatable {
  const GoalActivity({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.recurrence,
    required this.startDate,
    required this.targetValue,
    required this.targetUnit,
    required this.createdAt,
    this.recurrenceConfig,
    this.metric = ActivityMetric.boolean,
    this.progressSnapshot,
  });

  final String id;
  final String categoryId;
  final String title;
  final Recurrence recurrence;
  final String? recurrenceConfig;
  final DateTime startDate;
  final double targetValue;
  final GoalTargetUnit targetUnit;
  final ActivityMetric metric;
  final DateTime createdAt;

  /// Populated by the bloc during subscription. Not persisted.
  final GoalProgressSnapshot? progressSnapshot;

  GoalActivity copyWith({
    String? title,
    Recurrence? recurrence,
    String? recurrenceConfig,
    DateTime? startDate,
    double? targetValue,
    GoalTargetUnit? targetUnit,
    ActivityMetric? metric,
    GoalProgressSnapshot? progressSnapshot,
  }) =>
      GoalActivity(
        id: id,
        categoryId: categoryId,
        title: title ?? this.title,
        recurrence: recurrence ?? this.recurrence,
        recurrenceConfig: recurrenceConfig ?? this.recurrenceConfig,
        startDate: startDate ?? this.startDate,
        targetValue: targetValue ?? this.targetValue,
        targetUnit: targetUnit ?? this.targetUnit,
        metric: metric ?? this.metric,
        createdAt: createdAt,
        progressSnapshot: progressSnapshot ?? this.progressSnapshot,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'category_id': categoryId,
        'title': title,
        'recurrence_type': recurrence.wire,
        'recurrence_config': recurrenceConfig,
        'start_date': startDate.millisecondsSinceEpoch,
        'target_value': targetValue,
        'target_unit': targetUnit.wire,
        'metric': metric.wire,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory GoalActivity.fromMap(Map<String, Object?> m) => GoalActivity(
        id: m['id'] as String,
        categoryId: m['category_id'] as String,
        title: m['title'] as String,
        recurrence: Recurrence.parse(m['recurrence_type'] as String?),
        recurrenceConfig: m['recurrence_config'] as String?,
        startDate: DateTime.fromMillisecondsSinceEpoch(m['start_date'] as int),
        targetValue: ((m['target_value'] as num?) ?? 1).toDouble(),
        targetUnit: GoalTargetUnit.parse(m['target_unit'] as String?),
        metric: ActivityMetric.parse(m['metric'] as String?),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  @override
  List<Object?> get props => [
        id, categoryId, title, recurrence, recurrenceConfig, startDate,
        targetValue, targetUnit, metric, createdAt,
      ];
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/goals/domain/goal_activity_test.dart`

Expected: PASS.

- [ ] **Step 6: Write failing tests for `GoalActivityRepository`**

Create `test/features/goals/data/goal_activity_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/goals/data/category_repository.dart';
import 'package:todos/features/goals/data/goal_activity_repository.dart';
import 'package:todos/features/goals/domain/category.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/todos/domain/recurrence.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase db;
  late GoalActivityRepository repo;
  late CategoryRepository categories;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    repo = GoalActivityRepository(db);
    categories = CategoryRepository(db);
    await categories.insert(Category(
      id: 'c1', title: 'Health',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      archived: false,
    ));
  });
  tearDown(() async => db.close());

  GoalActivity makeActivity(String id, String categoryId, {String title = 'pushup'}) =>
      GoalActivity(
        id: id, categoryId: categoryId, title: title,
        recurrence: Recurrence.daily,
        startDate: DateTime(2026, 1, 1),
        targetValue: 15,
        targetUnit: GoalTargetUnit.perDay,
        metric: ActivityMetric.count,
        createdAt: DateTime(2026, 1, 1),
      );

  test('insert + listByCategory round-trip', () async {
    await repo.insert(makeActivity('a1', 'c1'));
    await repo.insert(makeActivity('a2', 'c1', title: 'meditate'));
    final list = await repo.listByCategory('c1');
    expect(list.map((a) => a.id), ['a1', 'a2']);
  });

  test('delete cascades to goal_logs', () async {
    await repo.insert(makeActivity('a1', 'c1'));
    await db.raw.insert('goal_logs', {
      'id': 'l1', 'goal_activity_id': 'a1', 'value': 1.0,
      'logged_at': 1000, 'created_at': 1000,
    });
    await repo.delete('a1');
    final logs = await db.raw.query('goal_logs', where: 'id = ?', whereArgs: ['l1']);
    expect(logs, isEmpty);
  });

  test('delete cascades to activities when category is deleted', () async {
    await repo.insert(makeActivity('a1', 'c1'));
    await categories.delete('c1');
    final list = await repo.listByCategory('c1');
    expect(list, isEmpty);
  });

  test('update persists new target_value and target_unit', () async {
    await repo.insert(makeActivity('a1', 'c1'));
    final updated = (await repo.getById('a1'))!.copyWith(
      targetValue: 90,
      targetUnit: GoalTargetUnit.perWeek,
    );
    await repo.update(updated);
    final reloaded = (await repo.getById('a1'))!;
    expect(reloaded.targetValue, 90);
    expect(reloaded.targetUnit, GoalTargetUnit.perWeek);
  });
}
```

- [ ] **Step 7: Run test to verify it fails**

Run: `flutter test test/features/goals/data/goal_activity_repository_test.dart`

Expected: FAIL — `GoalActivityRepository` still uses old `listByGoal` and old `goal_id` column.

- [ ] **Step 8: Update `GoalActivityRepository`**

Rewrite `lib/features/goals/data/goal_activity_repository.dart`:

```dart
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database.dart';
import '../../../core/database/schema.dart';
import '../domain/goal_activity.dart';

class GoalActivityRepository {
  GoalActivityRepository(this._db);
  final AppDatabase _db;
  Database get _raw => _db.raw;

  Future<void> insert(GoalActivity a) => _raw.insert(Tables.goalActivities, a.toMap());

  Future<List<GoalActivity>> listByCategory(String categoryId) async {
    final rows = await _raw.query(
      Tables.goalActivities,
      where: '${GoalActivityCols.categoryId} = ?',
      whereArgs: [categoryId],
      orderBy: '${GoalActivityCols.createdAt} ASC',
    );
    return rows.map(GoalActivity.fromMap).toList();
  }

  Future<void> delete(String id) => _raw.delete(
        Tables.goalActivities,
        where: '${GoalActivityCols.id} = ?',
        whereArgs: [id],
      );

  Future<void> update(GoalActivity a) => _raw.update(
        Tables.goalActivities,
        a.toMap(),
        where: '${GoalActivityCols.id} = ?',
        whereArgs: [a.id],
      );

  Future<GoalActivity?> getById(String id) async {
    final rows = await _raw.query(
      Tables.goalActivities,
      where: '${GoalActivityCols.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GoalActivity.fromMap(rows.first);
  }
}
```

- [ ] **Step 9: Run test to verify it passes**

Run: `flutter test test/features/goals/data/goal_activity_repository_test.dart`

Expected: PASS.

- [ ] **Step 10: Delete obsolete files**

```bash
git rm lib/features/goals/domain/activity_completion.dart \
       lib/features/goals/data/activity_completion_repository.dart \
       test/features/goals/data/repositories_test.dart
```

- [ ] **Step 11: Commit**

```bash
git add lib/features/goals/domain/goal_activity.dart lib/features/goals/data/goal_activity_repository.dart \
        lib/features/goals/domain/goal_progress_snapshot.dart \
        test/features/goals/domain/goal_activity_test.dart \
        test/features/goals/data/goal_activity_repository_test.dart
git commit -m "feat(goals): extend GoalActivity with start/target fields"
```

---

### Task 6: `GoalProgressSnapshot` computation

**Files:**
- Modify: `lib/features/goals/domain/goal_progress_snapshot.dart` (replace stub)
- Create: `test/features/goals/domain/goal_progress_snapshot_test.dart`

**Interfaces:**
- Consumes: `GoalActivity`, `GoalLog`, `Recurrence`, `PeriodCalculator`
- Produces: `GoalProgressSnapshot.compute({required GoalActivity activity, required DateTime now, required List<GoalLog> logs})`

Algorithm:
1. **Choose the period function** based on `activity.targetUnit`:
   - `perDay` → each calendar day
   - `perWeek` → each calendar week
   - `perMonth` → each calendar month
   - `perPeriod` → defer to `activity.recurrence`
2. **`periodsElapsed`** = number of period-starts `≥ startDate` whose period-end `≤ now`. Periods whose end is in the future don't count yet.
3. For each elapsed period, sum `GoalLog.value` whose `loggedAt` falls in `[periodStart, periodEnd]`. The period counts as completed iff:
   - boolean: any log with `value >= 1` exists in the period
   - count or duration: `sum >= activity.targetValue`
4. **`percent`** = `(periodsCompleted / periodsElapsed).clamp(0.0, 1.0)`.
5. **`lifetimeTotal`** = aggregate across all logs:
   - boolean → `GoalLifetimeTotalBoolean(logs.length)`
   - count → `GoalLifetimeTotalCount(logs.fold(0.0, (s, l) => s + l.value))`
   - duration → `GoalLifetimeTotalDuration(logs.fold(0, (s, l) => s + l.value.toInt()))`

- [ ] **Step 1: Write failing tests**

Create `test/features/goals/domain/goal_progress_snapshot_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_log.dart';
import 'package:todos/features/goals/domain/goal_progress_snapshot.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/todos/domain/recurrence.dart';

void main() {
  GoalActivity make({
    DateTime? startDate,
    double targetValue = 1,
    GoalTargetUnit targetUnit = GoalTargetUnit.perDay,
    ActivityMetric metric = ActivityMetric.boolean,
    Recurrence recurrence = Recurrence.daily,
  }) =>
      GoalActivity(
        id: 'a1', categoryId: 'c1', title: 't',
        recurrence: recurrence,
        startDate: startDate ?? DateTime(2026, 7, 1),
        targetValue: targetValue,
        targetUnit: targetUnit,
        metric: metric,
        createdAt: startDate ?? DateTime(2026, 7, 1),
      );

  GoalLog log(DateTime when, double value) => GoalLog(
        id: 'l', goalActivityId: 'a1', value: value,
        loggedAt: when, createdAt: when,
      );

  test('boolean: each day with one event counts as completed', () {
    final activity = make();
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 7, 5, 23, 59),
      logs: [
        log(DateTime(2026, 7, 1, 9), 1),
        log(DateTime(2026, 7, 3, 9), 1),
      ],
    );
    expect(snap.periodsElapsed, 5);
    expect(snap.periodsCompleted, 2);
    expect(snap.percent, closeTo(2 / 5, 1e-9));
    expect((snap.lifetimeTotal as GoalLifetimeTotalBoolean).count, 2);
  });

  test('count: perDay target of 15 sums daily logs', () {
    final activity = make(targetValue: 15, targetUnit: GoalTargetUnit.perDay, metric: ActivityMetric.count);
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 7, 3, 23, 59),
      logs: [
        log(DateTime(2026, 7, 1, 9), 10),
        log(DateTime(2026, 7, 2, 9), 20),
        log(DateTime(2026, 7, 3, 9), 5),
      ],
    );
    expect(snap.periodsElapsed, 3);
    expect(snap.periodsCompleted, 1);
    expect((snap.lifetimeTotal as GoalLifetimeTotalCount).total, 35);
  });

  test('perWeek target sums across the week', () {
    final activity = make(
      targetValue: 90,
      targetUnit: GoalTargetUnit.perWeek,
      metric: ActivityMetric.count,
      startDate: DateTime(2026, 6, 29), // Mon
    );
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 7, 12, 23, 59),  // Sun — end of week 2
      logs: [
        log(DateTime(2026, 7, 1), 50),
        log(DateTime(2026, 7, 4), 60),  // week 1: 110 ≥ 90
        log(DateTime(2026, 7, 8), 30),
        log(DateTime(2026, 7, 11), 40), // week 2: 70 < 90
      ],
    );
    expect(snap.periodsCompleted, 1);
    expect((snap.lifetimeTotal as GoalLifetimeTotalCount).total, 180);
  });

  test('perPeriod falls back to recurrence=weekly', () {
    final activity = make(
      targetUnit: GoalTargetUnit.perPeriod,
      metric: ActivityMetric.count,
      targetValue: 1,
      recurrence: Recurrence.weekly,
      startDate: DateTime(2026, 7, 6),
    );
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 7, 19, 23, 59),
      logs: [log(DateTime(2026, 7, 8), 1)],
    );
    expect(snap.periodsElapsed, 2);
    expect(snap.periodsCompleted, 1);
  });

  test('duration metric sums seconds', () {
    final activity = make(metric: ActivityMetric.duration, targetValue: 30, targetUnit: GoalTargetUnit.perDay);
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 7, 1, 23, 59),
      logs: [log(DateTime(2026, 7, 1, 9), 45)],
    );
    expect(snap.periodsCompleted, 1);
    expect((snap.lifetimeTotal as GoalLifetimeTotalDuration).totalSeconds, 45);
  });

  test('future periods are not counted', () {
    final activity = make(startDate: DateTime(2026, 7, 10));
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 7, 5),
      logs: const [],
    );
    expect(snap.periodsElapsed, 0);
    expect(snap.percent, 0.0);
  });

  test('month-end edge: monthly goal with start_date=Jan 31', () {
    final activity = make(
      targetUnit: GoalTargetUnit.perMonth,
      metric: ActivityMetric.boolean,
      targetValue: 1,
      startDate: DateTime(2026, 1, 31),
    );
    final snap = GoalProgressSnapshot.compute(
      activity: activity,
      now: DateTime(2026, 2, 28, 23, 59),
      logs: [log(DateTime(2026, 2, 1), 1)],
    );
    expect(snap.periodsElapsed, 1);
    expect(snap.periodsCompleted, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/goals/domain/goal_progress_snapshot_test.dart`

Expected: FAIL — `GoalProgressSnapshot.compute` not defined.

- [ ] **Step 3: Implement the snapshot**

Replace `lib/features/goals/domain/goal_progress_snapshot.dart`:

```dart
import '../../../core/utils/period_calculator.dart';
import '../../todos/domain/recurrence.dart';
import 'goal_activity.dart';
import 'goal_log.dart';
import 'goal_target_unit.dart';

class GoalProgressSnapshot {
  const GoalProgressSnapshot({
    required this.periodsElapsed,
    required this.periodsCompleted,
    required this.percent,
    required this.lifetimeTotal,
  });

  factory GoalProgressSnapshot.empty() => const GoalProgressSnapshot(
        periodsElapsed: 0,
        periodsCompleted: 0,
        percent: 0,
        lifetimeTotal: GoalLifetimeTotalBoolean(0),
      );

  factory GoalProgressSnapshot.compute({
    required GoalActivity activity,
    required DateTime now,
    required List<GoalLog> logs,
  }) {
    final per = _perFor(activity);
    final periods = <(DateTime, DateTime)>[];
    var cursor = per.anchor(activity.startDate);
    while (!per.end(cursor).isBefore(activity.startDate)) {
      final end = per.end(cursor);
      if (end.isAfter(now)) break;
      if (!end.isBefore(activity.startDate)) {
        periods.add((per.start(cursor), end));
      }
      cursor = per.next(cursor);
    }
    var completed = 0;
    for (final (start, end) in periods) {
      final inPeriod = logs
          .where((l) => !l.loggedAt.isBefore(start) && !l.loggedAt.isAfter(end))
          .toList();
      if (activity.metric == ActivityMetric.boolean) {
        if (inPeriod.any((l) => l.value >= 1)) completed++;
      } else {
        final sum = inPeriod.fold<double>(0, (s, l) => s + l.value);
        if (sum >= activity.targetValue) completed++;
      }
    }
    final pct = periods.isEmpty ? 0.0 : (completed / periods.length).clamp(0.0, 1.0);
    return GoalProgressSnapshot(
      periodsElapsed: periods.length,
      periodsCompleted: completed,
      percent: pct.toDouble(),
      lifetimeTotal: _lifetime(activity, logs),
    );
  }

  static _Per _perFor(GoalActivity a) {
    final unit = a.targetUnit;
    if (unit == GoalTargetUnit.perDay) return _Per.day;
    if (unit == GoalTargetUnit.perWeek) return _Per.week;
    if (unit == GoalTargetUnit.perMonth) return _Per.month;
    return switch (a.recurrence) {
      Recurrence.none => _Per.day,
      Recurrence.daily => _Per.day,
      Recurrence.weekly => _Per.week,
      Recurrence.monthly => _Per.month,
    };
  }

  static GoalLifetimeTotal _lifetime(GoalActivity a, List<GoalLog> logs) {
    switch (a.metric) {
      case ActivityMetric.boolean:
        return GoalLifetimeTotalBoolean(logs.length);
      case ActivityMetric.count:
        return GoalLifetimeTotalCount(logs.fold<double>(0, (s, l) => s + l.value));
      case ActivityMetric.duration:
        return GoalLifetimeTotalDuration(logs.fold<int>(0, (s, l) => s + l.value.toInt()));
    }
  }

  final int periodsElapsed;
  final int periodsCompleted;
  final double percent;
  final GoalLifetimeTotal lifetimeTotal;
}

class _Per {
  const _Per({required this.start, required this.end, required this.next, required this.anchor});
  final DateTime Function(DateTime) start;
  final DateTime Function(DateTime) end;
  final DateTime Function(DateTime) next;
  final DateTime Function(DateTime) anchor;

  static const day = _Per(
    start: PeriodCalculator.dayStart,
    end: PeriodCalculator.dayEnd,
    next: (d) => DateTime(d.year, d.month, d.day + 1),
    anchor: PeriodCalculator.dayStart,
  );
  static const week = _Per(
    start: PeriodCalculator.weekStart,
    end: PeriodCalculator.weekEnd,
    next: (d) => d.add(const Duration(days: 7)),
    anchor: PeriodCalculator.weekStart,
  );
  static const month = _Per(
    start: PeriodCalculator.monthStart,
    end: PeriodCalculator.monthEnd,
    next: (d) => (d.month == 12) ? DateTime(d.year + 1, 1, 1) : DateTime(d.year, d.month + 1, 1),
    anchor: PeriodCalculator.monthStart,
  );
}

sealed class GoalLifetimeTotal {
  const GoalLifetimeTotal();
}

class GoalLifetimeTotalBoolean extends GoalLifetimeTotal {
  const GoalLifetimeTotalBoolean(this.count);
  final int count;
}

class GoalLifetimeTotalCount extends GoalLifetimeTotal {
  const GoalLifetimeTotalCount(this.total);
  final double total;
}

class GoalLifetimeTotalDuration extends GoalLifetimeTotal {
  const GoalLifetimeTotalDuration(this.totalSeconds);
  final int totalSeconds;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/goals/domain/goal_progress_snapshot_test.dart`

Expected: PASS. If a week-boundary test fails because the period includes 8 days instead of 7, verify that `PeriodCalculator.weekStart` anchors to Monday and `PeriodCalculator.weekEnd` returns the same week's Sunday. If the month-end test fails because the loop iterates one period too many, confirm `month.end` returns Feb 28 for `Jan 31`'s anchor month.

- [ ] **Step 5: Commit**

```bash
git add lib/features/goals/domain/goal_progress_snapshot.dart test/features/goals/domain/goal_progress_snapshot_test.dart
git commit -m "feat(goals): add GoalProgressSnapshot computation"
```

---

### Task 7: `GoalBloc` — events, state, and handlers rewrite

**Files:**
- Modify: `lib/features/goals/presentation/bloc/goal_event.dart`
- Modify: `lib/features/goals/presentation/bloc/goal_state.dart`
- Modify: `lib/features/goals/presentation/bloc/goal_bloc.dart`
- Modify: `test/features/goals/presentation/bloc/goal_bloc_test.dart`

**Interfaces:**
- Consumes: `CategoryRepository`, `GoalActivityRepository`, `GoalLogRepository`, `GoalProgressSnapshot.compute`
- Produces events (full replacement):
  - `GoalsSubscriptionRequested`
  - `CategoryCreated({title, description?})`
  - `CategoryUpdated(category)`
  - `CategoryDeleted(id)`
  - `GoalActivityCreated({categoryId, title, metric, recurrence, recurrenceConfig?, startDate, targetValue, targetUnit})`
  - `GoalActivityUpdated(activity)`
  - `GoalActivityDeleted(id)`
  - `GoalLogBooleanToggled({goalActivityId, periodStart, periodEnd})`
  - `GoalLogCountAdded({goalActivityId, delta})`
  - `GoalLogDurationAdded({goalActivityId, seconds})`
  - `GoalLogDeleted(id)`
  - `GoalLogEdited(log)`
- Produces states:
  - `GoalInitial`, `GoalLoading`, `GoalsLoaded({categories, activitiesByCategoryId, logsByActivityId})`, `GoalErrorState(message)`

- [ ] **Step 1: Write failing bloc test**

Rewrite `test/features/goals/presentation/bloc/goal_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todos/features/goals/data/category_repository.dart';
import 'package:todos/features/goals/data/goal_activity_repository.dart';
import 'package:todos/features/goals/data/goal_log_repository.dart';
import 'package:todos/features/goals/domain/category.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_log.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:todos/features/goals/presentation/bloc/goal_event.dart';
import 'package:todos/features/goals/presentation/bloc/goal_state.dart';
import 'package:todos/features/todos/domain/recurrence.dart';
import 'package:uuid/uuid.dart';

class _MockCategories extends Mock implements CategoryRepository {}
class _MockActivities extends Mock implements GoalActivityRepository {}
class _MockLogs extends Mock implements GoalLogRepository {}

void main() {
  late _MockCategories categories;
  late _MockActivities activities;
  late _MockLogs logs;
  final fixedNow = DateTime(2026, 7, 5);

  setUpAll(() {
    registerFallbackValue(GoalLog(
      id: 'x', goalActivityId: 'x', value: 0,
      loggedAt: fixedNow, createdAt: fixedNow,
    ));
  });

  setUp(() {
    categories = _MockCategories();
    activities = _MockActivities();
    logs = _MockLogs();
    when(() => categories.getAll(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) async => [
              Category(id: 'c1', title: 'Health',
                createdAt: DateTime(2026, 1, 1),
                updatedAt: DateTime(2026, 1, 1),
                archived: false),
            ]);
    when(() => activities.listByCategory('c1')).thenAnswer((_) async => [
          GoalActivity(
            id: 'a1', categoryId: 'c1', title: 'pushup',
            recurrence: Recurrence.daily,
            startDate: DateTime(2026, 7, 1),
            targetValue: 15,
            targetUnit: GoalTargetUnit.perDay,
            metric: ActivityMetric.count,
            createdAt: DateTime(2026, 7, 1),
          ),
        ]);
    when(() => logs.listByActivity('a1')).thenAnswer((_) async => []);
  });

  GoalBloc build() => GoalBloc(
        categoryRepo: categories,
        activityRepo: activities,
        logRepo: logs,
        uuid: const Uuid(),
        now: () => fixedNow,
      );

  blocTest<GoalBloc, GoalState>(
    'SubscriptionRequested emits loaded with categories and precomputed snapshots',
    build: build,
    act: (b) => b.add(const GoalsSubscriptionRequested()),
    expect: () => [
      const GoalLoading(),
      predicate<GoalState>((s) =>
          s is GoalsLoaded &&
          s.categories.length == 1 &&
          s.activitiesByCategoryId['c1']!.length == 1 &&
          s.activitiesByCategoryId['c1']!.first.progressSnapshot != null),
    ],
  );

  blocTest<GoalBloc, GoalState>(
    'CategoryCreated inserts and reloads',
    build: () {
      when(() => categories.insert(any())).thenAnswer((_) async {});
      return build();
    },
    act: (b) => b.add(const CategoryCreated(title: 'Wealth')),
    verify: (_) => verify(() => categories.insert(any())).called(1),
  );

  blocTest<GoalBloc, GoalState>(
    'GoalLogBooleanToggled inserts one log row for an empty period',
    build: () {
      when(() => logs.listByActivity('a1')).thenAnswer((_) async => []);
      when(() => logs.listByActivityInRange('a1',
          from: any(named: 'from'), to: any(named: 'to')))
          .thenAnswer((_) async => []);
      when(() => logs.insert(any())).thenAnswer((_) async {});
      return build();
    },
    act: (b) => b.add(GoalLogBooleanToggled(
      goalActivityId: 'a1',
      periodStart: DateTime(2026, 7, 1),
      periodEnd: DateTime(2026, 7, 1, 23, 59, 59, 999),
    )),
    verify: (_) => verify(() => logs.insert(any())).called(1),
  );

  blocTest<GoalBloc, GoalState>(
    'GoalLogCountAdded inserts a log with the delta',
    build: () {
      when(() => logs.insert(any())).thenAnswer((_) async {});
      return build();
    },
    act: (b) => b.add(const GoalLogCountAdded(goalActivityId: 'a1', delta: 5)),
    verify: (_) {
      final captured = verify(() => logs.insert(captureAny())).captured.single as GoalLog;
      expect(captured.value, 5);
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/goals/presentation/bloc/goal_bloc_test.dart`

Expected: FAIL — new events and constructor don't exist.

- [ ] **Step 3: Rewrite `goal_event.dart`**

Replace `lib/features/goals/presentation/bloc/goal_event.dart` with the full event set defined under **Interfaces** above. Each event extends `GoalEvent` (Equatable). Use the field signatures listed in Interfaces verbatim.

- [ ] **Step 4: Rewrite `goal_state.dart`**

Replace `lib/features/goals/presentation/bloc/goal_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../domain/category.dart';
import '../../domain/goal_activity.dart';
import '../../domain/goal_log.dart';

abstract class GoalState extends Equatable {
  const GoalState();
  @override
  List<Object?> get props => [];
}

class GoalInitial extends GoalState {
  const GoalInitial();
}

class GoalLoading extends GoalState {
  const GoalLoading();
}

class GoalsLoaded extends GoalState {
  const GoalsLoaded({
    required this.categories,
    required this.activitiesByCategoryId,
    required this.logsByActivityId,
  });
  final List<Category> categories;
  final Map<String, List<GoalActivity>> activitiesByCategoryId;
  final Map<String, List<GoalLog>> logsByActivityId;

  @override
  List<Object?> get props => [categories, activitiesByCategoryId, logsByActivityId];
}

class GoalErrorState extends GoalState {
  const GoalErrorState(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
```

- [ ] **Step 5: Rewrite `goal_bloc.dart`**

Replace `lib/features/goals/presentation/bloc/goal_bloc.dart`:

```dart
import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/category_repository.dart';
import '../../data/goal_activity_repository.dart';
import '../../data/goal_log_repository.dart';
import '../../domain/category.dart';
import '../../domain/goal_activity.dart';
import '../../domain/goal_log.dart';
import '../../domain/goal_progress_snapshot.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  GoalBloc({
    required CategoryRepository categoryRepo,
    required GoalActivityRepository activityRepo,
    required GoalLogRepository logRepo,
    required Uuid uuid,
    DateTime Function()? now,
  })  : _categories = categoryRepo,
        _activities = activityRepo,
        _logs = logRepo,
        _uuid = uuid,
        _now = now ?? DateTime.now,
        super(const GoalInitial()) {
    on<GoalsSubscriptionRequested>(_onSubscribe);
    on<CategoryCreated>(_onCategoryCreated);
    on<CategoryUpdated>(_onCategoryUpdated);
    on<CategoryDeleted>(_onCategoryDeleted);
    on<GoalActivityCreated>(_onActivityCreated);
    on<GoalActivityUpdated>(_onActivityUpdated);
    on<GoalActivityDeleted>(_onActivityDeleted);
    on<GoalLogBooleanToggled>(_onLogBooleanToggled);
    on<GoalLogCountAdded>(_onLogCountAdded);
    on<GoalLogDurationAdded>(_onLogDurationAdded);
    on<GoalLogDeleted>(_onLogDeleted);
    on<GoalLogEdited>(_onLogEdited);
  }

  final CategoryRepository _categories;
  final GoalActivityRepository _activities;
  final GoalLogRepository _logs;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> _onSubscribe(GoalsSubscriptionRequested e, Emitter<GoalState> emit) async {
    emit(const GoalLoading());
    try {
      final cats = await _categories.getAll();
      final activitiesByCat = <String, List<GoalActivity>>{};
      final logsByAct = <String, List<GoalLog>>{};
      final at = _now();
      for (final c in cats) {
        final acts = await _activities.listByCategory(c.id);
        activitiesByCat[c.id] = acts;
        for (final a in acts) {
          logsByAct[a.id] = await _logs.listByActivity(a.id);
        }
      }
      final withSnapshots = <String, List<GoalActivity>>{};
      activitiesByCat.forEach((catId, acts) {
        withSnapshots[catId] = [
          for (final a in acts)
            a.copyWith(
              progressSnapshot: GoalProgressSnapshot.compute(
                activity: a, now: at, logs: logsByAct[a.id] ?? const []),
            ),
        ];
      });
      emit(GoalsLoaded(
        categories: cats,
        activitiesByCategoryId: withSnapshots,
        logsByActivityId: logsByAct,
      ));
    } catch (err) {
      emit(GoalErrorState(err.toString()));
    }
  }

  Future<void> _onCategoryCreated(CategoryCreated e, Emitter<GoalState> emit) async {
    final at = _now();
    await _categories.insert(Category(
      id: _uuid.v4(), title: e.title, description: e.description,
      createdAt: at, updatedAt: at, archived: false,
    ));
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onCategoryUpdated(CategoryUpdated e, Emitter<GoalState> emit) async {
    await _categories.update(e.category.copyWith(updatedAt: _now()));
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onCategoryDeleted(CategoryDeleted e, Emitter<GoalState> emit) async {
    await _categories.delete(e.id);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onActivityCreated(GoalActivityCreated e, Emitter<GoalState> emit) async {
    final a = GoalActivity(
      id: _uuid.v4(), categoryId: e.categoryId, title: e.title,
      metric: e.metric, recurrence: e.recurrence, recurrenceConfig: e.recurrenceConfig,
      startDate: e.startDate, targetValue: e.targetValue, targetUnit: e.targetUnit,
      createdAt: _now(),
    );
    await _activities.insert(a);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onActivityUpdated(GoalActivityUpdated e, Emitter<GoalState> emit) async {
    await _activities.update(e.activity);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onActivityDeleted(GoalActivityDeleted e, Emitter<GoalState> emit) async {
    await _activities.delete(e.id);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onLogBooleanToggled(GoalLogBooleanToggled e, Emitter<GoalState> emit) async {
    final existing = await _logs.listByActivityInRange(
      e.goalActivityId, from: e.periodStart, to: e.periodEnd,
    );
    if (existing.isNotEmpty) {
      await _logs.delete(existing.first.id);
    } else {
      await _logs.insert(GoalLog(
        id: _uuid.v4(), goalActivityId: e.goalActivityId, value: 1.0,
        loggedAt: _now(), createdAt: _now(),
      ));
    }
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onLogCountAdded(GoalLogCountAdded e, Emitter<GoalState> emit) async {
    await _logs.insert(GoalLog(
      id: _uuid.v4(), goalActivityId: e.goalActivityId, value: e.delta.toDouble(),
      loggedAt: _now(), createdAt: _now(),
    ));
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onLogDurationAdded(GoalLogDurationAdded e, Emitter<GoalState> emit) async {
    await _logs.insert(GoalLog(
      id: _uuid.v4(), goalActivityId: e.goalActivityId, value: e.seconds.toDouble(),
      loggedAt: _now(), createdAt: _now(),
    ));
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onLogDeleted(GoalLogDeleted e, Emitter<GoalState> emit) async {
    await _logs.delete(e.id);
    add(const GoalsSubscriptionRequested());
  }

  Future<void> _onLogEdited(GoalLogEdited e, Emitter<GoalState> emit) async {
    await _logs.update(e.log);
    add(const GoalsSubscriptionRequested());
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/goals/presentation/bloc/goal_bloc_test.dart`

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/goals/presentation/bloc/goal_event.dart \
        lib/features/goals/presentation/bloc/goal_state.dart \
        lib/features/goals/presentation/bloc/goal_bloc.dart \
        test/features/goals/presentation/bloc/goal_bloc_test.dart
git commit -m "feat(goals): rewrite bloc for categories + goals + logs"
```

---

### Task 8: `CategoryHeader` widget

**Files:**
- Create: `lib/features/goals/presentation/widgets/category_header.dart`
- Create: `test/features/goals/presentation/widgets/category_header_test.dart`

**Interfaces:**
- Consumes: `Category`, optional `List<Widget> children`, callbacks `onEdit(Category)`, `onDelete(Category)`, `initiallyExpanded`
- Produces: an `ExpansionTile` with title/subtitle, an overflow menu (`Edit Category` / `Delete Category`), and child widgets.

- [ ] **Step 1: Write failing widget test**

Create `test/features/goals/presentation/widgets/category_header_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/goals/presentation/widgets/category_header_test.dart`

Expected: FAIL — `CategoryHeader` not defined.

- [ ] **Step 3: Implement `CategoryHeader`**

Create `lib/features/goals/presentation/widgets/category_header.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/category.dart';

class CategoryHeader extends StatelessWidget {
  const CategoryHeader({
    super.key,
    required this.category,
    required this.initiallyExpanded,
    required this.onEdit,
    required this.onDelete,
    this.children = const [],
  });

  final Category category;
  final bool initiallyExpanded;
  final List<Widget> children;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(category.title),
        subtitle: (category.description ?? '').isEmpty ? null : Text(category.description!),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit(category);
            if (v == 'delete') onDelete(category);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit Category')),
            PopupMenuItem(value: 'delete', child: Text('Delete Category')),
          ],
        ),
        children: children,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/goals/presentation/widgets/category_header_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/goals/presentation/widgets/category_header.dart test/features/goals/presentation/widgets/category_header_test.dart
git commit -m "feat(goals): add CategoryHeader widget"
```

---

### Task 9: `GoalTile` widget

**Files:**
- Create: `lib/features/goals/presentation/widgets/goal_tile.dart`
- Create: `test/features/goals/presentation/widgets/goal_tile_test.dart`

**Interfaces:**
- Consumes: `GoalActivity` (with populated `progressSnapshot`), callback `onTap(GoalActivity)`
- Produces: a widget rendering the goal title, target-expression chip, lifetime-total chip, thin linear progress bar, and `"X of Y periods completed"` text.

- [ ] **Step 1: Write failing widget test**

Create `test/features/goals/presentation/widgets/goal_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_progress_snapshot.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/goals/presentation/widgets/goal_tile.dart';
import 'package:todos/features/todos/domain/recurrence.dart';

void main() {
  GoalActivity activity({
    String title = 'pushup',
    double targetValue = 15,
    GoalTargetUnit targetUnit = GoalTargetUnit.perDay,
    ActivityMetric metric = ActivityMetric.count,
    GoalProgressSnapshot? snapshot,
  }) =>
      GoalActivity(
        id: 'a1', categoryId: 'c1', title: title,
        recurrence: Recurrence.daily,
        startDate: DateTime(2026, 7, 1),
        targetValue: targetValue, targetUnit: targetUnit, metric: metric,
        createdAt: DateTime(2026, 7, 1),
        progressSnapshot: snapshot,
      );

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders title and target expression chip', (tester) async {
    await tester.pumpWidget(host(GoalTile(activity: activity(), onTap: (_) {})));
    expect(find.text('pushup'), findsOneWidget);
    expect(find.text('15 / day'), findsOneWidget);
  });

  testWidgets('renders lifetime total for boolean metric', (tester) async {
    await tester.pumpWidget(host(GoalTile(
      activity: activity(
        metric: ActivityMetric.boolean,
        targetValue: 1,
        snapshot: const GoalProgressSnapshot(
          periodsElapsed: 5, periodsCompleted: 2, percent: 0.4,
          lifetimeTotal: GoalLifetimeTotalBoolean(2),
        ),
      ),
      onTap: (_) {},
    )));
    expect(find.text('2 days'), findsOneWidget);
    expect(find.text('2 of 5 periods completed'), findsOneWidget);
  });

  testWidgets('renders lifetime total for count metric', (tester) async {
    await tester.pumpWidget(host(GoalTile(
      activity: activity(snapshot: const GoalProgressSnapshot(
        periodsElapsed: 3, periodsCompleted: 1, percent: 0.33,
        lifetimeTotal: GoalLifetimeTotalCount(35),
      )),
      onTap: (_) {},
    )));
    expect(find.text('35 total'), findsOneWidget);
  });

  testWidgets('renders lifetime total for duration metric', (tester) async {
    await tester.pumpWidget(host(GoalTile(
      activity: activity(
        metric: ActivityMetric.duration,
        targetValue: 1800,
        snapshot: const GoalProgressSnapshot(
          periodsElapsed: 1, periodsCompleted: 1, percent: 1.0,
          lifetimeTotal: GoalLifetimeTotalDuration(7200),
        ),
      ),
      onTap: (_) {},
    )));
    expect(find.text('2h 0m'), findsOneWidget);
  });

  testWidgets('taps onTap', (tester) async {
    GoalActivity? tapped;
    await tester.pumpWidget(host(GoalTile(activity: activity(), onTap: (a) => tapped = a)));
    await tester.tap(find.text('pushup'));
    expect(tapped, isNotNull);
    expect(tapped!.id, 'a1');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/goals/presentation/widgets/goal_tile_test.dart`

Expected: FAIL — `GoalTile` not defined.

- [ ] **Step 3: Implement `GoalTile`**

Create `lib/features/goals/presentation/widgets/goal_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/goal_activity.dart';
import '../../domain/goal_progress_snapshot.dart';
import '../../domain/goal_target_unit.dart';

class GoalTile extends StatelessWidget {
  const GoalTile({super.key, required this.activity, required this.onTap});

  final GoalActivity activity;
  final ValueChanged<GoalActivity> onTap;

  String _unitLabel(GoalTargetUnit u) => switch (u) {
        GoalTargetUnit.perDay => 'day',
        GoalTargetUnit.perWeek => 'week',
        GoalTargetUnit.perMonth => 'month',
        GoalTargetUnit.perPeriod => 'period',
      };

  String _formatCount(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  String _formatTotal(GoalLifetimeTotal t) {
    if (t is GoalLifetimeTotalBoolean) return '${t.count} days';
    if (t is GoalLifetimeTotalCount) {
      final v = t.total;
      return '${v == v.roundToDouble() ? v.toInt() : v} total';
    }
    if (t is GoalLifetimeTotalDuration) {
      final secs = t.totalSeconds;
      final h = secs ~/ 3600;
      final m = (secs % 3600) ~/ 60;
      if (h > 0) return '${h}h ${m}m';
      if (m > 0) return '${m}m ${secs % 60}s';
      return '${secs}s';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final snap = activity.progressSnapshot ?? GoalProgressSnapshot.empty();
    final unit = _unitLabel(activity.targetUnit);
    final targetChip = '${_formatCount(activity.targetValue)} / $unit';
    final progressText = snap.periodsElapsed == 0
        ? 'not started'
        : '${snap.periodsCompleted} of ${snap.periodsElapsed} periods completed';
    return InkWell(
      onTap: () => onTap(activity),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(activity.title, style: Theme.of(context).textTheme.titleMedium)),
                Chip(label: Text(targetChip)),
                const SizedBox(width: 8),
                Chip(label: Text(_formatTotal(snap.lifetimeTotal))),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: snap.percent, minHeight: 2),
            const SizedBox(height: 4),
            Text(progressText, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/goals/presentation/widgets/goal_tile_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/goals/presentation/widgets/goal_tile.dart test/features/goals/presentation/widgets/goal_tile_test.dart
git commit -m "feat(goals): add GoalTile widget"
```

---

### Task 10: `LogSheet` modal for adding/editing `GoalLog`

**Files:**
- Create: `lib/features/goals/presentation/widgets/log_sheet.dart`
- Create: `test/features/goals/presentation/widgets/log_sheet_test.dart`

**Interfaces:**
- Consumes: required `goalActivityId`, optional `existing: GoalLog?`
- Produces: a modal bottom sheet with `value`, `loggedAt`, `notes` fields. On submit, pops with a `GoalLog` value (caller dispatches `GoalLogCountAdded`, `GoalLogDurationAdded`, or `GoalLogEdited`).

- [ ] **Step 1: Write failing widget test**

Create `test/features/goals/presentation/widgets/log_sheet_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/goals/presentation/widgets/log_sheet_test.dart`

Expected: FAIL — `showLogSheet` not defined.

- [ ] **Step 3: Implement `LogSheet`**

Create `lib/features/goals/presentation/widgets/log_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/goal_log.dart';

Future<GoalLog?> showLogSheet({
  required BuildContext context,
  required String goalActivityId,
  GoalLog? existing,
}) {
  return showModalBottomSheet<GoalLog>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => LogSheet(goalActivityId: goalActivityId, existing: existing),
  );
}

class LogSheet extends StatefulWidget {
  const LogSheet({super.key, required this.goalActivityId, this.existing});
  final String goalActivityId;
  final GoalLog? existing;

  @override
  State<LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<LogSheet> {
  late final TextEditingController _value;
  late final TextEditingController _notes;
  late DateTime _loggedAt;

  @override
  void initState() {
    super.initState();
    _value = TextEditingController(
        text: widget.existing == null ? '' : widget.existing!.value.toString());
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _loggedAt = widget.existing?.loggedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_value.text.trim());
    if (value == null) return;
    final log = GoalLog(
      id: widget.existing?.id ?? 'new',
      goalActivityId: widget.goalActivityId,
      value: value,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      loggedAt: _loggedAt,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(log);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.existing == null ? 'Log entry' : 'Edit entry',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Value'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Logged at'),
            subtitle: Text(_loggedAt.toIso8601String().substring(0, 16)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _loggedAt,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) setState(() => _loggedAt = picked);
            },
          ),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('Save')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/goals/presentation/widgets/log_sheet_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/goals/presentation/widgets/log_sheet.dart test/features/goals/presentation/widgets/log_sheet_test.dart
git commit -m "feat(goals): add LogSheet for adding/editing GoalLog"
```

---

### Task 11: `CategoryFormPage`

**Files:**
- Create: `lib/features/goals/presentation/pages/category_form_page.dart`
- Create: `test/features/goals/presentation/pages/category_form_page_test.dart`

**Interfaces:**
- Consumes: optional `existing: Category?`
- Produces: a form with `title` and `description` fields. Submit dispatches `CategoryCreated` or `CategoryUpdated`.

- [ ] **Step 1: Write failing widget test**

Create `test/features/goals/presentation/pages/category_form_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/category.dart';
import 'package:todos/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:todos/features/goals/presentation/bloc/goal_event.dart';
import 'package:todos/features/goals/presentation/pages/category_form_page.dart';

class _RecordingBloc extends GoalBloc {
  _RecordingBloc() : super(
        categoryRepo: _NoopRepo(),
        activityRepo: _NoopRepo(),
        logRepo: _NoopRepo(),
        uuid: const _NoopUuid(),
      );
  final dispatched = <GoalEvent>[];
  @override
  void add(GoalEvent event) => dispatched.add(event);
}

class _NoopRepo implements dynamic {}
class _NoopUuid implements dynamic {
  const _NoopUuid();
  @override
  String v4() => 'fixed';
}

void main() {
  testWidgets('Create mode: empty title blocks submit', (tester) async {
    final bloc = _RecordingBloc();
    await tester.pumpWidget(MaterialApp(home: BlocProvider.value(
      value: bloc, child: const CategoryFormPage(),
    )));
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pump();
    expect(bloc.dispatched, isEmpty);
  });

  testWidgets('Create mode: dispatching CategoryCreated on submit', (tester) async {
    final bloc = _RecordingBloc();
    await tester.pumpWidget(MaterialApp(home: BlocProvider.value(
      value: bloc, child: const CategoryFormPage(),
    )));
    await tester.enterText(find.byType(TextField).first, 'Health');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pump();
    expect(bloc.dispatched.whereType<CategoryCreated>(), hasLength(1));
  });

  testWidgets('Edit mode: prefills title and dispatches CategoryUpdated', (tester) async {
    final bloc = _RecordingBloc();
    final existing = Category(
      id: 'c1', title: 'Health', description: 'old',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      archived: false,
    );
    await tester.pumpWidget(MaterialApp(home: BlocProvider.value(
      value: bloc, child: CategoryFormPage(existing: existing),
    )));
    expect(find.text('Health'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Wellness');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    final updated = bloc.dispatched.whereType<CategoryUpdated>().single;
    expect(updated.category.title, 'Wellness');
    expect(updated.category.id, 'c1');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/goals/presentation/pages/category_form_page_test.dart`

Expected: FAIL — `CategoryFormPage` not defined.

- [ ] **Step 3: Implement `CategoryFormPage`**

Create `lib/features/goals/presentation/pages/category_form_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/category.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';

class CategoryFormPage extends StatefulWidget {
  const CategoryFormPage({super.key, this.existing});
  final Category? existing;

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  late final TextEditingController _title;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _description = TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final desc = _description.text.trim();
    final bloc = context.read<GoalBloc>();
    if (widget.existing == null) {
      bloc.add(CategoryCreated(
        title: title,
        description: desc.isEmpty ? null : desc,
      ));
    } else {
      bloc.add(CategoryUpdated(widget.existing!.copyWith(
        title: title,
        description: desc.isEmpty ? null : desc,
      )));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Category' : 'New Category')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: _description, decoration: const InputDecoration(labelText: 'Description (optional)')),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: Text(isEdit ? 'Save' : 'Add')),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/goals/presentation/pages/category_form_page_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/goals/presentation/pages/category_form_page.dart \
        test/features/goals/presentation/pages/category_form_page_test.dart
git commit -m "feat(goals): add CategoryFormPage"
```

---

### Task 12: `GoalFormPage` (rewrites `goal_form_page.dart`)

**Files:**
- Rewrite: `lib/features/goals/presentation/pages/goal_form_page.dart`
- Create: `test/features/goals/presentation/pages/goal_form_page_test.dart`
- Delete: `lib/features/goals/presentation/pages/activity_form_page.dart`, `lib/features/goals/presentation/widgets/activity_tile.dart`

**Interfaces:**
- Consumes: optional `existing: GoalActivity?`, optional `categoryId: String?`, `BlocProvider<GoalBloc>`
- Produces: a form with `title`, `metric` (dropdown), `recurrence` (dropdown), `startDate` (date picker, defaults today), `targetValue` (number), `targetUnit` (dropdown), `category` (dropdown — required). Submit dispatches `GoalActivityCreated` or `GoalActivityUpdated`.

- [ ] **Step 1: Write failing widget test**

Create `test/features/goals/presentation/pages/goal_form_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/goals/domain/category.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:todos/features/goals/presentation/bloc/goal_event.dart';
import 'package:todos/features/goals/presentation/bloc/goal_state.dart';
import 'package:todos/features/goals/presentation/pages/goal_form_page.dart';
import 'package:todos/features/todos/domain/recurrence.dart';

class _StubBloc extends GoalBloc {
  _StubBloc() : super(
        categoryRepo: _NoopRepo(),
        activityRepo: _NoopRepo(),
        logRepo: _NoopRepo(),
        uuid: const _NoopUuid(),
      );
  final dispatched = <GoalEvent>[];
  @override
  void add(GoalEvent e) => dispatched.add(e);
  @override
  GoalState get state => const GoalsLoaded(
        categories: [
          Category(id: 'c1', title: 'Health',
            createdAt: null as dynamic, updatedAt: null as dynamic, archived: false),
        ],
        activitiesByCategoryId: {},
        logsByActivityId: {},
      );
}
class _NoopRepo implements dynamic {}
class _NoopUuid implements dynamic { const _NoopUuid(); @override String v4() => 'fixed'; }

void main() {
  testWidgets('Create mode: dispatching GoalActivityCreated with selected category', (tester) async {
    final bloc = _StubBloc();
    await tester.pumpWidget(MaterialApp(home: BlocProvider.value(
      value: bloc, child: const GoalFormPage(),
    )));
    await tester.enterText(find.byType(TextField).first, 'pushup');
    await tester.tap(find.text('Add'));
    await tester.pump();
    final ev = bloc.dispatched.whereType<GoalActivityCreated>().single;
    expect(ev.title, 'pushup');
    expect(ev.categoryId, 'c1');
  });

  testWidgets('Edit mode: prefills and dispatches GoalActivityUpdated', (tester) async {
    final bloc = _StubBloc();
    final existing = GoalActivity(
      id: 'a1', categoryId: 'c1', title: 'pushup',
      recurrence: Recurrence.daily,
      startDate: DateTime(2026, 7, 1),
      targetValue: 15, targetUnit: GoalTargetUnit.perDay,
      metric: ActivityMetric.count,
      createdAt: DateTime(2026, 7, 1),
    );
    await tester.pumpWidget(MaterialApp(home: BlocProvider.value(
      value: bloc, child: GoalFormPage(existing: existing),
    )));
    expect(find.text('pushup'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'meditate');
    await tester.tap(find.text('Save'));
    await tester.pump();
    final ev = bloc.dispatched.whereType<GoalActivityUpdated>().single;
    expect(ev.activity.title, 'meditate');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/goals/presentation/pages/goal_form_page_test.dart`

Expected: FAIL — current `GoalFormPage` doesn't accept `categoryId` and doesn't dispatch `GoalActivityCreated`.

- [ ] **Step 3: Rewrite `GoalFormPage`**

Replace `lib/features/goals/presentation/pages/goal_form_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/category.dart';
import '../../domain/goal_activity.dart';
import '../../domain/goal_target_unit.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../../../todos/domain/recurrence.dart';

class GoalFormPage extends StatefulWidget {
  const GoalFormPage({super.key, this.existing, this.categoryId});
  final GoalActivity? existing;
  final String? categoryId;

  @override
  State<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends State<GoalFormPage> {
  late final TextEditingController _title;
  late final TextEditingController _targetValue;
  late ActivityMetric _metric;
  late Recurrence _recurrence;
  late DateTime _startDate;
  late GoalTargetUnit _targetUnit;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _targetValue = TextEditingController(text: e == null ? '' : e.targetValue.toString());
    _metric = e?.metric ?? ActivityMetric.boolean;
    _recurrence = e?.recurrence ?? Recurrence.daily;
    _startDate = e?.startDate ?? DateTime.now();
    _targetUnit = e?.targetUnit ?? GoalTargetUnit.perDay;
    _selectedCategoryId = widget.categoryId ?? e?.categoryId;
  }

  @override
  void dispose() {
    _title.dispose();
    _targetValue.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    final value = double.tryParse(_targetValue.text.trim()) ?? 1;
    if (title.isEmpty || _selectedCategoryId == null) return;
    final bloc = context.read<GoalBloc>();
    if (widget.existing == null) {
      bloc.add(GoalActivityCreated(
        categoryId: _selectedCategoryId!,
        title: title, metric: _metric, recurrence: _recurrence,
        startDate: _startDate, targetValue: value, targetUnit: _targetUnit,
      ));
    } else {
      bloc.add(GoalActivityUpdated(widget.existing!.copyWith(
        categoryId: _selectedCategoryId,
        title: title, metric: _metric, recurrence: _recurrence,
        startDate: _startDate, targetValue: value, targetUnit: _targetUnit,
      )));
    }
    Navigator.of(context).pop();
  }

  String _unitLabel(GoalTargetUnit u) => switch (u) {
        GoalTargetUnit.perDay => 'per day',
        GoalTargetUnit.perWeek => 'per week',
        GoalTargetUnit.perMonth => 'per month',
        GoalTargetUnit.perPeriod => 'per period',
      };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GoalBloc>().state;
    final categories = state is GoalsLoaded ? state.categories : const <Category>[];
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Goal' : 'New Goal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            DropdownButtonFormField<ActivityMetric>(
              value: _metric,
              decoration: const InputDecoration(labelText: 'Metric'),
              items: const [
                DropdownMenuItem(value: ActivityMetric.boolean, child: Text('Yes / No')),
                DropdownMenuItem(value: ActivityMetric.count, child: Text('Counter')),
                DropdownMenuItem(value: ActivityMetric.duration, child: Text('Duration')),
              ],
              onChanged: (v) => setState(() => _metric = v ?? _metric),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Recurrence>(
              value: _recurrence,
              decoration: const InputDecoration(labelText: 'Recording cadence'),
              items: const [
                DropdownMenuItem(value: Recurrence.none, child: Text('None')),
                DropdownMenuItem(value: Recurrence.daily, child: Text('Daily')),
                DropdownMenuItem(value: Recurrence.weekly, child: Text('Weekly')),
                DropdownMenuItem(value: Recurrence.monthly, child: Text('Monthly')),
              ],
              onChanged: (v) => setState(() => _recurrence = v ?? _recurrence),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(_startDate.toIso8601String().substring(0, 10)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetValue,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target value'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GoalTargetUnit>(
              value: _targetUnit,
              decoration: const InputDecoration(labelText: 'Target unit'),
              items: [
                for (final u in GoalTargetUnit.values)
                  DropdownMenuItem(value: u, child: Text(_unitLabel(u))),
              ],
              onChanged: (v) => setState(() => _targetUnit = v ?? _targetUnit),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in categories)
                  DropdownMenuItem(value: c.id, child: Text(c.title)),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: Text(isEdit ? 'Save' : 'Add')),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/goals/presentation/pages/goal_form_page_test.dart`

Expected: PASS.

- [ ] **Step 5: Delete obsolete files**

```bash
git rm -f lib/features/goals/presentation/pages/activity_form_page.dart \
       lib/features/goals/presentation/widgets/activity_tile.dart || true
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/goals/presentation/pages/goal_form_page.dart \
        test/features/goals/presentation/pages/goal_form_page_test.dart
git commit -m "feat(goals): rewrite GoalFormPage with target expression"
```

---

### Task 13: `GoalDetailPage`

**Files:**
- Rewrite: `lib/features/goals/presentation/pages/goal_detail_page.dart`
- Create: `test/features/goals/presentation/pages/goal_detail_page_test.dart`

**Interfaces:**
- Consumes: required `activity: GoalActivity`, `BlocProvider<GoalBloc>` (for state + dispatching log events)
- Produces: a page with header card (target expression, progress, lifetime total), "Recent logs" list, boolean tap-to-log button OR `+` FAB that opens `LogSheet` for count/duration goals. Edit/Delete actions on the AppBar with confirmation dialogs.

- [ ] **Step 1: Write failing widget test**

Create `test/features/goals/presentation/pages/goal_detail_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/goals/data/category_repository.dart';
import 'package:todos/features/goals/data/goal_activity_repository.dart';
import 'package:todos/features/goals/data/goal_log_repository.dart';
import 'package:todos/features/goals/domain/goal_activity.dart';
import 'package:todos/features/goals/domain/goal_target_unit.dart';
import 'package:todos/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:todos/features/goals/presentation/bloc/goal_event.dart';
import 'package:todos/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:todos/features/todos/domain/recurrence.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    await db.raw.insert('categories', {
      'id': 'c1', 'title': 'Health',
      'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      'updated_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      'archived': 0,
    });
    await db.raw.insert('goal_activities', {
      'id': 'a1', 'category_id': 'c1', 'title': 'pushup',
      'recurrence_type': 'daily',
      'start_date': DateTime(2026, 7, 1).millisecondsSinceEpoch,
      'target_value': 15, 'target_unit': 'per_day', 'metric': 'count',
      'created_at': DateTime(2026, 7, 1).millisecondsSinceEpoch,
    });
  });
  tearDown(() async => db.close());

  GoalActivity makeCountActivity() => GoalActivity(
        id: 'a1', categoryId: 'c1', title: 'pushup',
        recurrence: Recurrence.daily,
        startDate: DateTime(2026, 7, 1),
        targetValue: 15, targetUnit: GoalTargetUnit.perDay,
        metric: ActivityMetric.count,
        createdAt: DateTime(2026, 7, 1),
      );

  GoalActivity makeBooleanActivity() => GoalActivity(
        id: 'a1', categoryId: 'c1', title: 'meditate',
        recurrence: Recurrence.daily,
        startDate: DateTime(2026, 7, 1),
        targetValue: 1, targetUnit: GoalTargetUnit.perDay,
        metric: ActivityMetric.boolean,
        createdAt: DateTime(2026, 7, 1),
      );

  Widget host(GoalActivity a) => MaterialApp(home: BlocProvider(
        create: (_) => GoalBloc(
          categoryRepo: CategoryRepository(db),
          activityRepo: GoalActivityRepository(db),
          logRepo: GoalLogRepository(db),
          uuid: const Uuid(),
        )..add(const GoalsSubscriptionRequested()),
        child: GoalDetailPage(activity: a),
      ));

  testWidgets('renders title and target expression', (tester) async {
    await tester.pumpWidget(host(makeCountActivity()));
    await tester.pumpAndSettle();
    expect(find.text('pushup'), findsWidgets);
    expect(find.text('15 / day'), findsOneWidget);
  });

  testWidgets('count metric shows + FAB and renders an existing log row', (tester) async {
    await db.raw.insert('goal_logs', {
      'id': 'l1', 'goal_activity_id': 'a1', 'value': 10.0,
      'logged_at': DateTime(2026, 7, 1).millisecondsSinceEpoch,
      'created_at': DateTime(2026, 7, 1).millisecondsSinceEpoch,
    });
    await tester.pumpWidget(host(makeCountActivity()));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('boolean metric shows a Log today button, no FAB', (tester) async {
    await tester.pumpWidget(host(makeBooleanActivity()));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Log today'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/goals/presentation/pages/goal_detail_page_test.dart`

Expected: FAIL — `GoalDetailPage` doesn't accept `activity` (the old page takes `goal`).

- [ ] **Step 3: Rewrite `GoalDetailPage`**

Replace `lib/features/goals/presentation/pages/goal_detail_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/goal_activity.dart';
import '../../domain/goal_log.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../widgets/log_sheet.dart';
import 'goal_form_page.dart';

class GoalDetailPage extends StatelessWidget {
  const GoalDetailPage({super.key, required this.activity});
  final GoalActivity activity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activity.title),
        actions: [
          IconButton(
            tooltip: 'Edit goal',
            icon: const Icon(Icons.edit),
            onPressed: () {
              final bloc = context.read<GoalBloc>();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc, child: GoalFormPage(existing: activity),
                ),
              ));
            },
          ),
          IconButton(
            tooltip: 'Delete goal',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      floatingActionButton: activity.metric == ActivityMetric.boolean
          ? null
          : FloatingActionButton(
              onPressed: () => _addLog(context),
              child: const Icon(Icons.add),
            ),
      body: BlocBuilder<GoalBloc, GoalState>(
        builder: (context, state) {
          if (state is! GoalsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = state.logsByActivityId[activity.id] ?? const <GoalLog>[];
          final df = DateFormat.yMMMd();
          final snap = activity.progressSnapshot;
          final unitLabel = activity.targetUnit.wire.replaceAll('per_', '');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(activity.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('${_formatCount(activity.targetValue)} / $unitLabel'),
              if (snap != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: snap.percent, minHeight: 4),
                const SizedBox(height: 4),
                Text('${snap.periodsCompleted} of ${snap.periodsElapsed} periods completed'),
              ],
              const SizedBox(height: 24),
              if (activity.metric == ActivityMetric.boolean)
                FilledButton(onPressed: () => _toggleToday(context), child: const Text('Log today')),
              const SizedBox(height: 24),
              Text('Recent logs', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (logs.isEmpty) const Text('No logs yet.'),
              for (final log in logs.take(50))
                ListTile(
                  dense: true,
                  title: Text(_formatCount(log.value)),
                  subtitle: Text(df.format(log.loggedAt)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') context.read<GoalBloc>().add(GoalLogDeleted(log.id));
                      if (v == 'edit') _editLog(context, log);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatCount(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${activity.title}"?'),
        content: const Text('This will permanently delete the goal and every log entry.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<GoalBloc>().add(GoalActivityDeleted(activity.id));
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _addLog(BuildContext context) async {
    final bloc = context.read<GoalBloc>();
    final result = await showLogSheet(context: context, goalActivityId: activity.id);
    if (result == null || !context.mounted) return;
    if (activity.metric == ActivityMetric.count) {
      bloc.add(GoalLogCountAdded(goalActivityId: activity.id, delta: result.value.toInt()));
    } else if (activity.metric == ActivityMetric.duration) {
      bloc.add(GoalLogDurationAdded(goalActivityId: activity.id, seconds: result.value.toInt()));
    }
  }

  Future<void> _editLog(BuildContext context, GoalLog log) async {
    final bloc = context.read<GoalBloc>();
    final result = await showLogSheet(context: context, goalActivityId: activity.id, existing: log);
    if (result == null || !context.mounted) return;
    bloc.add(GoalLogEdited(GoalLog(
      id: log.id,
      goalActivityId: log.goalActivityId,
      value: result.value,
      notes: result.notes,
      loggedAt: result.loggedAt,
      createdAt: log.createdAt,
    )));
  }

  Future<void> _toggleToday(BuildContext context) async {
    final now = DateTime.now();
    final bloc = context.read<GoalBloc>();
    bloc.add(GoalLogBooleanToggled(
      goalActivityId: activity.id,
      periodStart: DateTime(now.year, now.month, now.day),
      periodEnd: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    ));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/goals/presentation/pages/goal_detail_page_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/goals/presentation/pages/goal_detail_page.dart \
        test/features/goals/presentation/pages/goal_detail_page_test.dart
git commit -m "feat(goals): rewrite GoalDetailPage with header card + log list"
```

---

### Task 14: `GoalListPage` (tree view)

**Files:**
- Rewrite: `lib/features/goals/presentation/pages/goal_list_page.dart`
- Create: `test/features/goals/presentation/pages/goal_list_page_test.dart`

**Interfaces:**
- Consumes: `AppDatabaseScope`, `Uuid`, `GoalBloc`, `CategoryHeader`, `GoalTile`, `CategoryFormPage`, `GoalFormPage`, `GoalDetailPage`
- Produces: a `StatelessWidget` that renders the tree view of categories + goals, with a FAB action sheet for "New Category" / "New Goal" and delete confirmations.

- [ ] **Step 1: Write failing widget test**

Create `test/features/goals/presentation/pages/goal_list_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/core/database/app_database_scope.dart';
import 'package:todos/features/goals/presentation/pages/goal_list_page.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    await db.raw.insert('categories', {
      'id': 'c1', 'title': 'Health',
      'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      'updated_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      'archived': 0,
    });
    await db.raw.insert('goal_activities', {
      'id': 'a1', 'category_id': 'c1', 'title': 'pushup',
      'recurrence_type': 'daily',
      'start_date': DateTime(2026, 7, 1).millisecondsSinceEpoch,
      'target_value': 15, 'target_unit': 'per_day', 'metric': 'count',
      'created_at': DateTime(2026, 7, 1).millisecondsSinceEpoch,
    });
  });
  tearDown(() async => db.close());

  Widget host() => AppDatabaseScope(
        database: db,
        child: const MaterialApp(home: GoalListPage()),
      );

  testWidgets('renders category and its goal', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('pushup'), findsOneWidget);
  });

  testWidgets('shows empty state when no categories', (tester) async {
    await db.raw.delete('goal_activities');
    await db.raw.delete('categories');
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.textContaining('No categories'), findsOneWidget);
  });

  testWidgets('delete category requires confirmation', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Category'));
    await tester.pumpAndSettle();
    expect(find.text('Delete "Health"?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Health'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/goals/presentation/pages/goal_list_page_test.dart`

Expected: FAIL — `GoalListPage` doesn't exist yet.

- [ ] **Step 3: Inspect `AppDatabaseScope` signature**

Read `lib/core/database/app_database_scope.dart` and use its actual constructor signature in the test host. The widget tree in `GoalListPage` calls `AppDatabaseScope.of(context)` to get the database — match that contract.

- [ ] **Step 4: Implement `GoalListPage`**

Replace `lib/features/goals/presentation/pages/goal_list_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database_scope.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/category_repository.dart';
import '../../data/goal_activity_repository.dart';
import '../../data/goal_log_repository.dart';
import '../../domain/category.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../widgets/category_header.dart';
import '../widgets/goal_tile.dart';
import 'category_form_page.dart';
import 'goal_detail_page.dart';
import 'goal_form_page.dart';

class GoalListPage extends StatelessWidget {
  const GoalListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return BlocProvider(
      create: (_) => GoalBloc(
        categoryRepo: CategoryRepository(db),
        activityRepo: GoalActivityRepository(db),
        logRepo: GoalLogRepository(db),
        uuid: const Uuid(),
      )..add(const GoalsSubscriptionRequested()),
      child: const _GoalListView(),
    );
  }
}

class _GoalListView extends StatelessWidget {
  const _GoalListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openFabSheet(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<GoalBloc, GoalState>(
        builder: (context, state) {
          if (state is GoalLoading || state is GoalInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GoalErrorState) {
            return _ErrorView(message: state.message, onRetry: () {
              context.read<GoalBloc>().add(const GoalsSubscriptionRequested());
            });
          }
          final loaded = state as GoalsLoaded;
          if (loaded.categories.isEmpty) {
            return const EmptyState(
              title: 'No categories yet',
              subtitle: 'Tap + to add a category or a goal.',
              icon: Icons.flag_outlined,
            );
          }
          return ListView(
            children: [
              for (final c in loaded.categories)
                CategoryHeader(
                  category: c,
                  initiallyExpanded: true,
                  onEdit: (cat) => _openCategoryForm(context, cat),
                  onDelete: (cat) => _confirmDeleteCategory(context, cat),
                  children: [
                    for (final a in loaded.activitiesByCategoryId[c.id] ?? const <GoalActivity>[])
                      GoalTile(activity: a, onTap: (act) => _openGoalDetail(context, act)),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Add goal'),
                      onTap: () => _openGoalForm(context, categoryId: c.id),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  void _openFabSheet(BuildContext context) {
    final bloc = context.read<GoalBloc>();
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text('New Category'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openCategoryForm(context, null);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('New Goal'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openGoalForm(context, categoryId: null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategoryForm(BuildContext context, Category? existing) {
    final bloc = context.read<GoalBloc>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc, child: CategoryFormPage(existing: existing),
      ),
    ));
  }

  void _openGoalForm(BuildContext context, {String? categoryId, GoalActivity? existing}) {
    final bloc = context.read<GoalBloc>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: GoalFormPage(categoryId: categoryId, existing: existing),
      ),
    ));
  }

  void _openGoalDetail(BuildContext context, GoalActivity activity) {
    final bloc = context.read<GoalBloc>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc, child: GoalDetailPage(activity: activity),
      ),
    ));
  }

  Future<void> _confirmDeleteCategory(BuildContext context, Category cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${cat.title}"?'),
        content: const Text(
          'This will permanently delete the category and every goal and log inside it.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<GoalBloc>().add(CategoryDeleted(cat.id));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Error: $message'),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/goals/presentation/pages/goal_list_page_test.dart`

Expected: PASS. If the delete test fails, confirm the FK cascade is set up correctly in Task 1.

- [ ] **Step 6: Commit**

```bash
git add lib/features/goals/presentation/pages/goal_list_page.dart \
        test/features/goals/presentation/pages/goal_list_page_test.dart
git commit -m "feat(goals): tree-view GoalListPage with category headers"
```

---

### Task 15: Whole-feature regression + end-to-end smoke

**Files:** none — runs the full test suite and rebuilds + reinstalls the APK.

- [ ] **Step 1: Run the entire goals test directory**

Run: `flutter test test/features/goals/ test/core/database/migrations_test.dart`

Expected: PASS — all bloc, repository, domain, and widget tests succeed.

- [ ] **Step 2: Run `flutter analyze`**

Run: `flutter analyze`

Expected: no errors. Warnings about the `_NoopRepo` classes used in form-page tests are acceptable.

- [ ] **Step 3: Build and install the debug APK on the emulator**

```bash
flutter build apk --debug
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5554 shell am force-stop com.example.todos
adb -s emulator-5554 shell am start -n com.example.todos/.MainActivity
```

Expected: app launches without crashing; previous Goals data has been cleared (clean-slate migration).

- [ ] **Step 4: Verify the new flow on the emulator**

On the running app:
1. Tap **Goals** in the bottom nav — empty state shown.
2. Tap **+**, then **New Category** — title "Health", submit. Category appears with `Edit Category` / `Delete Category` overflow menu.
3. Tap **+** inside the category — `New Goal`, title "pushup", metric=Counter, cadence=Daily, start date=today, target value=15, target unit=per day, category=Health. Submit.
4. Tap the goal — header card shows target expression and progress; tap **+** to add a log value of 10. The list updates immediately and the tile shows updated progress.
5. Long-press a log row → Edit / Delete.

- [ ] **Step 5: Final commit (only if Step 1–4 surfaced a fix)**

If any test failed or the on-device run revealed a bug, fix it and commit:

```bash
git add -A
git commit -m "fix(goals): regression fixes from end-to-end verification"
```

(No commit if everything passed.)

---

## Self-Review

**Spec coverage:**
- Data model (categories / goal_activities extension / goal_logs) → Tasks 1, 2, 3, 5.
- Migration v4 (drop old, add new, FK cascade) → Task 1.
- GoalTargetUnit enum → Task 4.
- GoalProgressSnapshot compute (3 metrics × 4 targetUnits, period boundaries) → Task 6.
- Domain types (Category, GoalLog) and Equatable → Tasks 2, 3, 5.
- Bloc rewrite (events, state, snapshot attach, all CRUD) → Task 7.
- UI: tree view (CategoryHeader default-expanded, collapsible, click-to-detail) → Tasks 8, 14.
- UI: CategoryFormPage, GoalFormPage (target fields + category picker), GoalDetailPage (logs list + boolean toggle + count/duration FAB) → Tasks 11, 12, 13.
- UI: LogSheet → Task 10.
- UI: GoalTile (target chip, lifetime chip, progress bar, period counter) → Task 9.
- Confirmation dialogs on every destructive action → Tasks 8, 11, 13, 14.
- Cascade delete (category → activities → logs) → verified in Task 5 repository test.
- E2E verification on emulator → Task 15.

**Placeholders:** none.

**Type consistency:** `Category`, `GoalLog`, `GoalActivity` field names and types match across Tasks 2, 3, 5, 7, and the UI tasks. `GoalProgressSnapshot.compute` signature matches Task 7's call site. `showLogSheet` returns `Future<GoalLog?>`; callers handle the nullable case (Task 13).