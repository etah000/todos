# Goals Redesign: Categories + Goals

## Goal

Replace the current Goals tab with a two-level structure: top-level **Categories** are simple labels (e.g. "Health", "Wealth"); each Category contains one or more **Goals** that have a start date, a target expression, and a per-event log. Users can create, edit, and delete both Categories and Goals.

The redesign generalises the existing Goals feature so a single goal can be evaluated against a target like "15 reps/day" or "90 reps/week" independent of how often the user actually records (the recording cadence is independent of the target cadence).

## Current State

- `Goal` has `startDate`, `endDate`, `title`, `description`. The current UX uses start/end to define a window, with activities living underneath.
- `GoalActivity` has `title`, `recurrence` (period boundary), `metric` (boolean / count / duration), `totalCount`, `totalSeconds`. It logs against an `ActivityCompletion` table that de-duplicates one completion per period.
- `GoalBloc` wires CRUD + the three log events (`ActivityCompletionToggled`, `ActivityCountLogged`, `ActivityDurationLogged`).
- Pages: `GoalListPage` shows a list of goals (each with `title`, `startDate`, `endDate`). Tapping a row opens `GoalDetailPage` which shows activities and a `WeeklyProgressCard`. New activities are added through `ActivityFormPage`.

The current model collapses two distinct ideas:
1. A *time-bound goal window* (start/end), and
2. A *measurable target* (the activity's metric + target).

The user wants to separate these: the top level becomes a free-standing label, and the per-target object owns its own start date and target expression.

## Design

### Mental model

- **Category** — a label, nothing more. Examples: "Health", "Wealth", "Learning". No dates, no progress.
- **Goal** (the renamed, extended `GoalActivity`) — the thing the user tracks. Has a metric, a recording cadence (recurrence), a start date, and a target expression ("N per day/week/month/period").
- **GoalLog** — one event entry against a Goal. Replaces `ActivityCompletion` and the `totalCount`/`totalSeconds` running totals. Aggregates are computed from `GoalLog` rows.

### Data model

#### `categories` (new, replaces `goals`)

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT PRIMARY KEY | uuid |
| `title` | TEXT NOT NULL | e.g. "Health" |
| `description` | TEXT NULL | optional |
| `created_at` | INTEGER NOT NULL | ms epoch |
| `updated_at` | INTEGER NOT NULL | ms epoch |
| `archived` | INTEGER NOT NULL DEFAULT 0 | soft-delete |

No `start_date` / `end_date`. No FK.

#### `goal_activities` (extend existing table, rename `goal_id` → `category_id`)

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT PRIMARY KEY | uuid |
| `category_id` | TEXT NOT NULL | FK → `categories(id)` ON DELETE CASCADE |
| `title` | TEXT NOT NULL | "pushup", "meditate" |
| `metric` | TEXT NOT NULL | `boolean` / `count` / `duration` (existing `ActivityMetric`) |
| `recurrence_type` | TEXT NOT NULL | `none` / `daily` / `weekly` / `monthly` — drives period boundaries for stats |
| `recurrence_config` | TEXT NULL | weekday mask for weekly, day-of-month for monthly |
| `start_date` | INTEGER NOT NULL | when this goal became active; gates the progress calculation |
| `target_value` | REAL NOT NULL DEFAULT 1 | the "N" |
| `target_unit` | TEXT NOT NULL DEFAULT `'per_period'` | `per_day` / `per_week` / `per_month` / `per_period` |
| `created_at` | INTEGER NOT NULL | ms epoch |

Removed columns: `total_count`, `total_seconds`. Replaced by aggregating `goal_logs`.

#### `goal_logs` (new, replaces `activity_completions`)

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT PRIMARY KEY | uuid |
| `goal_activity_id` | TEXT NOT NULL | FK → `goal_activities(id)` ON DELETE CASCADE |
| `value` | REAL NOT NULL | 1.0 for boolean events, the count, or duration in seconds |
| `notes` | TEXT NULL | optional |
| `logged_at` | INTEGER NOT NULL | the event timestamp |
| `created_at` | INTEGER NOT NULL | row insert time |

### Migration (v4)

- `Migrations.currentVersion` → `4`.
- `onUpgrade` for v3→v4: drop `activity_completions`, drop `goal_activities`, drop `goals`; create the three new tables (`categories`, `goal_activities` with new columns, `goal_logs`).
- No data preservation. The user explicitly chose "clean slate".

### Domain types

- `Category` — `id`, `title`, `description?`, `createdAt`, `updatedAt`, `archived`. `toMap` / `fromMap` / `copyWith` / `Equatable`.
- `GoalActivity` — extended with `startDate`, `targetValue`, `targetUnit`. Removes `totalCount` / `totalSeconds`. Adds a non-persisted field `progressSnapshot` that the bloc populates during subscription. Snapshot is an immutable value object (`GoalProgressSnapshot`) with:
  - `periodsElapsed: int` — number of target_units' periods from `startDate` to `now`
  - `periodsCompleted: int` — number of periods that hit `target_value`
  - `percent: double` — `periodsCompleted / periodsElapsed`, clamped `[0.0, 1.0]`
  - `lifetimeTotal: GoalLifetimeTotal` — sealed-ish record (variant per metric):
    - boolean → `count: int`
    - count → `total: double`
    - duration → `totalSeconds: int`
- `GoalLog` — `id`, `goalActivityId`, `value`, `notes?`, `loggedAt`, `createdAt`.
- New enum `GoalTargetUnit { perDay, perWeek, perMonth, perPeriod }`.

### Progress snapshot math

The snapshot is computed in the bloc with an injected `now` clock so it is fully testable.

- **`periodsElapsed`** = number of periods of the chosen `targetUnit` that have fully elapsed between `startDate` and `now`. `per_period` falls back to the activity's `recurrence`.
- **Boolean periods:** a period counts as completed iff there is at least one `GoalLog` with `value >= 1` inside it (matches the "tap to check off" UX).
- **Count periods:** sum of `value` of all `GoalLog`s in the period; completed iff `sum >= targetValue`.
- **Duration periods:** sum of `value` (seconds); completed iff `sum >= targetValue`.
- **`lifetimeTotal`** sums all `GoalLog.value` over the entire lifetime of the goal. The UI formats this:
  - boolean → `"<n> days"` (count of distinct event rows)
  - count → `"<n> total"`
  - duration → `"Xd Yh Zm Ws"` if `< 1d`, otherwise `"Xd Yh Zm"` (trim trailing zeros; show only the largest two non-zero units if more than one day, to keep the chip compact)

### Bloc / events

`GoalBloc` keeps its name and file location. State becomes `GoalsLoaded({ categories, activitiesByCategoryId, logsByActivityId })`. Events:

| Event | Purpose |
|---|---|
| `GoalsSubscriptionRequested` | load + recompute snapshots |
| `CategoryCreated({title, description?})` | new |
| `CategoryUpdated(category)` | rename / re-describe |
| `CategoryDeleted(id)` | cascades to activities + logs |
| `GoalActivityCreated({categoryId, title, metric, recurrence, recurrenceConfig?, startDate, targetValue, targetUnit})` | new goal |
| `GoalActivityUpdated(activity)` | edit |
| `GoalActivityDeleted(id)` | cascades to logs |
| `GoalLogBooleanToggled({goalActivityId, periodStart, periodEnd})` | inserts one `GoalLog` row if none exists in the period; if one exists, deletes it (so re-tapping the same day un-logs that day) |
| `GoalLogCountAdded({goalActivityId, delta})` | inserts a `GoalLog` with `value = delta` |
| `GoalLogDurationAdded({goalActivityId, seconds})` | inserts a `GoalLog` with `value = seconds` |
| `GoalLogDeleted(id)` | removes one event |
| `GoalLogEdited(log)` | updates value/notes/logged_at |

Subscription eagerly loads all categories, all activities, and all logs for those activities. For v1 this is fine; the data set stays small. If performance becomes an issue, switch to per-activity lazy load via a `GoalDetailBloc`.

### Presentation

#### `GoalsListPage` (renames today's `GoalListPage`)

- Bloc provider + tree of `CategoryHeader` widgets.
- `FAB` opens an action sheet with two items: "New Category" and "New Goal". "New Category" → `CategoryFormPage`. "New Goal" → `GoalFormPage` (which includes a category picker dropdown).
- Empty state: "No categories yet. Tap + to add one."

#### `CategoryHeader`

- `ExpansionTile` with `initiallyExpanded: true`, `tilePadding` matching the current style.
- Title = category title; subtitle = category description (if present).
- Trailing: 3-dot overflow menu → `Edit Category` / `Delete Category`. Delete uses a confirm dialog matching the logs/countdown pattern.
- Children: list of `GoalTile`s, plus an inline `+ Add goal` row at the bottom that opens `GoalFormPage` with the category pre-selected.

#### `GoalTile`

Custom row, not a `ListTile`. Shows:

- Title (large)
- Target expression chip: `"15 / day"`, `"90 / week"`, `"3 / month"`, `"1 / period"`
- Lifetime total chip on the right (formatted per metric)
- Linear progress bar (thin, 2 px) — value = `snapshot.percent`
- Below the bar: `"3 of 12 periods completed"`

Tap → `GoalDetailPage`.

#### `GoalDetailPage` (new)

- AppBar: title = goal title; actions: Edit, Delete (both with confirmation).
- Body:
  - Header card: target expression, progress bar, `"X / Y periods completed"`, lifetime total chip.
  - "Recent logs" list: most recent 50 logs, descending by `logged_at`, with relative date ("Today 9:14 AM", "Yesterday", "Jul 12"). Each row has an overflow menu → Edit / Delete.
  - Boolean metric: a single "Log today" button that dispatches `GoalLogBooleanToggled` for the current day.
  - Other metrics: a `+` FAB that opens a modal sheet — fields: value (number), timestamp (defaults to now), notes (optional). Submit dispatches `GoalLogCountAdded` / `GoalLogDurationAdded` (or `GoalLogEdited` if editing).

#### `CategoryFormPage` (new)

Title field (required), description field (optional), Submit.

#### `GoalFormPage` (replaces `ActivityFormPage`)

Fields: title, metric (segmented), recurrence (segmented), start date (date picker, default today), target value (number), target unit (segmented), category (dropdown). Submit dispatches `GoalActivityCreated` / `GoalActivityUpdated`.

### Data flow

`GoalBloc` is the single source of truth for the list and the detail page. `GoalDetailPage` reads from the same bloc via `BlocProvider.value`, so a log edit on the detail page refreshes the list's `GoalTile` snapshot on pop.

### Error handling

- Bloc wraps subscription and each mutation in `try`/`catch`; on failure emits `GoalErrorState(message)`. The view shows a centered error widget with a Retry button.
- Forms validate inline: title non-empty; `targetValue > 0`; `startDate` no more than one day in the future.
- All deletes go through `AlertDialog` confirmations.
- Deleting a Category cascades to its activities and logs via `ON DELETE CASCADE`.

### Testing

| Layer | Type | Coverage |
|---|---|---|
| `Category`, `GoalActivity`, `GoalLog` | unit | `toMap`/`fromMap` round-trip, `copyWith`, `Equatable` props |
| `GoalProgressSnapshot` | unit | 3 metrics × 4 targetUnits × recurrence × period-boundary edge cases (week rollover, month-end) |
| Repositories | sqflite_ffi integration | CRUD + cascade delete |
| `GoalBloc` | bloc_test | subscription emits loaded with snapshots; create/update/delete cycle; boolean-toggle dedupes per period; count/duration events insert and aggregate; snapshot recomputes when logs change |
| `GoalsListPage`, `GoalDetailPage` | widget test | tree rendering, navigation, delete dialogs |

Period-boundary math is the highest-risk piece. All snapshot tests inject `now` via the bloc's existing `DateTime Function()?` constructor parameter so the clock is pinned.

### Risks

1. **Recurrence vs targetUnit ambiguity.** A goal with `recurrence=weekly` and `targetUnit=perDay` means "every day inside the week is its own period". Resolved by treating `targetUnit` as the strict period definition and `recurrence` only as the cadence hint for the UI ("I check this off daily"). Documented in the spec; the snapshot tests cover this case explicitly.
2. **Month-end edge cases.** `recurrence=monthly` with `recurrence_config='31'` and a February start needs to handle Feb 28/29. Tests pin time at these transitions.
3. **State shape.** Carrying `progressSnapshot` on `GoalActivity` blurs value-object and view-model boundaries. Accepted per design approval.
4. **Eager log loading.** All logs load at subscription time. Acceptable for v1; switch to lazy load if needed.

## Open Questions

None. The user approved the data model, bloc/domain shape, UI plan, and the error-handling/testing/risk section in this brainstorming session.