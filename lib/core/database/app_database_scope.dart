// lib/core/database/app_database_scope.dart
import 'package:flutter/widgets.dart';

import 'database.dart';

class AppDatabaseScope extends InheritedWidget {
  const AppDatabaseScope({
    super.key,
    required this.database,
    required super.child,
  });

  final AppDatabase database;

  static AppDatabase of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppDatabaseScope>();
    assert(scope != null, 'AppDatabaseScope not found in widget tree');
    return scope!.database;
  }

  @override
  bool updateShouldNotify(AppDatabaseScope oldWidget) =>
      oldWidget.database != database;
}
