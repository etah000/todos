# Todos

A local-first Android app for four everyday things: **Todos**, **Logs**, **Goals**, and **Countdowns**. No accounts, no cloud — your data lives in a local SQLite database.

## Features

- **Todos** — one-time or periodic (daily / weekly / monthly), with local reminder notifications and a "finish in advance" rule that respects the current period.
- **Logs** — define what you want to track (weight, mood, anything with a number), add entries, see a line chart for this week or this month.
- **Goals** — set a goal with a time range, add periodic activities, see your progress at a glance.
- **Countdown** — add events with a target date, see the days remaining.

## Run

Requirements: Flutter 3.22+, Android SDK, an Android device or emulator.

```bash
flutter pub get
flutter run -d <device>
```

## Test

```bash
flutter test
```

Tests rely on the system sqlite3 library. The sqlite3 build hook is configured in `pubspec.yaml` to link against the OS-provided SQLite library:

```bash
flutter test
```

## Architecture

Feature-first folder layout under `lib/features/`. State managed with `flutter_bloc`. Persistence in a single local SQLite database (`sqflite`). Routing via `go_router` with a `StatefulShellRoute` for the 4 bottom-nav tabs. Charts via `fl_chart`. Local notifications via `flutter_local_notifications`. Heavy use of pure-Dart domain models with TDD on models, repositories, and blocs.

See `docs/superpowers/plans/2026-06-17-todos-flutter-android-app.md` for the full implementation plan.
