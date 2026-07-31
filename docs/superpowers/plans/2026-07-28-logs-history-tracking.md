# Logs History Tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Logs support tracked items, periodic numeric entries, and week/month history charts with clear navigation.

**Architecture:** Keep the existing `LogItem` and `LogEntry` model. Tighten the presentation layer so `LogListPage` is the tracked-item list, `LogChartPage` is the per-item history page, and `LogChart` renders points by actual logged time.

**Tech Stack:** Flutter, flutter_bloc, sqflite/sqflite_common_ffi, fl_chart, flutter_test.

## Global Constraints

- Keep feature code under `lib/features/logs/`.
- Keep tests mirrored under `test/features/logs/`.
- Use existing BLoC, repository, database, and routing patterns.
- Do not change the existing logs database schema for this feature.
- Use TDD: write a failing focused test before production code for each behavior change.

---

### Task 1: Clarify Logs List Navigation

**Files:**
- Modify: `lib/features/logs/presentation/pages/log_list_page.dart`
- Test: `test/features/logs/presentation/pages/log_list_page_test.dart`

**Interfaces:**
- Consumes: `LogListPage`, `AppDatabaseScope`, `AppDatabase.open`, `LogItemRepository`, `LogEntryRepository`
- Produces: list rows where row tap opens `LogChartPage`, row plus opens `LogFormPage`

- [ ] **Step 1: Write the failing test**

Create `test/features/logs/presentation/pages/log_list_page_test.dart` with a widget test that seeds one `LogItem`, renders `LogListPage`, taps the row plus and expects `Log weight`, returns, then taps the row title and expects history title `weight`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/logs/presentation/pages/log_list_page_test.dart`

Expected before implementation: FAIL if row navigation or bloc scoping does not match the intended behavior.

- [ ] **Step 3: Implement minimal UI behavior**

In `log_list_page.dart`, keep app-bar plus for new tracked items. Keep row plus for add-entry. Ensure tapping the row title/body or chevron opens `LogChartPage` with `BlocProvider.value`. Make labels and subtitles describe tracker summaries clearly.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/logs/presentation/pages/log_list_page_test.dart`

Expected after implementation: PASS.

### Task 2: Render Chart Points By Logged Time

**Files:**
- Modify: `lib/features/logs/presentation/widgets/log_chart.dart`
- Test: `test/features/logs/presentation/widgets/log_chart_test.dart`

**Interfaces:**
- Consumes: `LogChart(entries: List<LogEntry>)`
- Produces: `LineChartData` where `LineChartBarData.spots[*].x` is derived from each entry's `loggedAt.millisecondsSinceEpoch`

- [ ] **Step 1: Write the failing test**

Create `test/features/logs/presentation/widgets/log_chart_test.dart` with a widget test that renders three unevenly spaced entries and inspects the `LineChart` widget. Assert that spot x-values equal each entry's logged timestamp, not sequential indexes.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/logs/presentation/widgets/log_chart_test.dart`

Expected before implementation: FAIL because current x-values are `0.0`, `1.0`, and `2.0`.

- [ ] **Step 3: Implement minimal chart mapping**

In `log_chart.dart`, sort entries by `loggedAt`, create `FlSpot(entry.loggedAt.millisecondsSinceEpoch.toDouble(), entry.value)`, set `minX` and `maxX` from the sorted first and last logged timestamps, and keep readable date labels on the bottom axis.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/logs/presentation/widgets/log_chart_test.dart`

Expected after implementation: PASS.

### Task 3: Make Detail Page A History Panel

**Files:**
- Modify: `lib/features/logs/presentation/pages/log_chart_page.dart`
- Modify: `lib/features/logs/presentation/pages/log_form_page.dart` if formatting or save-flow cleanup is required
- Test: `test/features/logs/presentation/pages/log_chart_page_test.dart`

**Interfaces:**
- Consumes: `LogChartPage(item: LogItem)`, `LogEntryRepository.listByItemInRange`
- Produces: detail page with week/month range, chart or empty state, recent entries list, plus button add-entry flow, and no indefinite spinner on load errors

- [ ] **Step 1: Extend the failing tests**

Update `test/features/logs/presentation/pages/log_chart_page_test.dart` to cover a populated current-week range. Seed one `LogItem` and at least one current-week `LogEntry`, render `LogChartPage`, wait for async load, and expect the page title plus a recent value row. Keep the existing empty-state regression test.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/logs/presentation/pages/log_chart_page_test.dart`

Expected before implementation: FAIL because the detail page does not expose a recent entries list.

- [ ] **Step 3: Implement minimal detail panel**

In `log_chart_page.dart`, keep repository initialization in `didChangeDependencies`, preserve error handling, and replace the body with a vertically scrollable detail panel containing `LogChart`, a range-specific empty state, and a compact recent entries list. Ensure the plus button wraps `LogFormPage` in `BlocProvider.value` and reloads both detail data and the shared `LogBloc`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/logs/presentation/pages/log_chart_page_test.dart`

Expected after implementation: PASS.

### Task 4: Final Verification

**Files:**
- Review: `lib/features/logs/presentation/pages/log_list_page.dart`
- Review: `lib/features/logs/presentation/pages/log_chart_page.dart`
- Review: `lib/features/logs/presentation/widgets/log_chart.dart`
- Review: `test/features/logs/presentation/`

**Interfaces:**
- Consumes: all previous tasks
- Produces: verified logs workflow

- [ ] **Step 1: Format changed Dart files**

Run: `dart format lib/features/logs test/features/logs`

Expected: formatter completes successfully.

- [ ] **Step 2: Run focused Logs tests**

Run: `flutter test test/features/logs`

Expected: all Logs tests pass.

- [ ] **Step 3: Run full test suite**

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 4: Manual emulator test**

Run: `flutter run -d emulator-5554`, then manually verify: Logs tab -> row tap opens history -> plus opens entry form -> save a value -> history returns without spinner or crash.

Expected: the app remains running and the history page shows chart or empty/recent data state.
