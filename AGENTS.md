# Repository Guidelines

## Project Structure & Module Organization

This is a local-first Flutter Android app. Application code is in `lib/`, with shared infrastructure in `lib/core/` and feature code under `lib/features/`. Features are organized into `domain/`, `data/`, and `presentation/` layers; presentation state uses BLoCs and events/states. Routing and app startup are in `lib/routes.dart`, `lib/app.dart`, and `lib/main.dart`. Tests mirror the production layout under `test/` and cover models, repositories, and BLoCs. Android-specific configuration is under `android/`; design and implementation notes are in `docs/`.

## Build, Test, and Development Commands

Run these from the repository root:

```bash
flutter pub get                         # Install Dart/Flutter dependencies
dart format lib test                    # Format Dart sources
flutter analyze                         # Run the configured linter and analyzer
flutter test                            # Run the full test suite
DART_DEFINE_SOURCE=system flutter test  # Use system sqlite3 for FFI tests
flutter run -d <device>                 # Run on an Android device/emulator
flutter build apk                       # Build an Android APK
```

Tests use `sqflite_common_ffi` and require the system `sqlite3` library in the development environment. Use the `DART_DEFINE_SOURCE=system` form when the default SQLite build hook cannot locate it.

## Coding Style & Naming Conventions

Use standard Dart formatting with two-space indentation and trailing commas for readable widget trees. Keep names in Dart style: `PascalCase` for classes, `camelCase` for members and variables, and `snake_case.dart` for files. Prefer `const` constructors/literals and `final` locals where possible; follow the rules in `analysis_options.yaml`. Keep feature-specific code within its feature and use existing BLoC, repository, and database patterns.

## Testing Guidelines

Use `flutter_test` for unit and widget tests, `bloc_test` for BLoC behavior, and Mocktail for collaborators. Name files with the `_test.dart` suffix and place them in the matching `test/` subdirectory. Add or update tests for domain rules, persistence changes, and state transitions; run the focused test first, then `flutter test` before submitting.

## Commit & Pull Request Guidelines

Use short, imperative Conventional Commit-style subjects with an optional scope, matching history such as `feat(goals): ...`, `feat(shell): ...`, `fix: ...`, and `docs: ...`. Pull requests should explain the user-visible or architectural change, identify tests run, link the relevant issue or plan when applicable, and include screenshots or device details for UI or Android behavior changes.

## Security & Configuration Tips

The app is intentionally local-first. Do not commit secrets, generated build output, device-specific configuration, or user database files. Keep notification permissions and Android manifest changes scoped to the feature that needs them.
