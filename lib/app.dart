// lib/app.dart
import 'package:flutter/material.dart';

import 'core/database/app_database_scope.dart';
import 'core/database/database.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_scope.dart';
import 'routes.dart';

class TodosApp extends StatefulWidget {
  const TodosApp({super.key, required this.database});
  final AppDatabase database;

  @override
  State<TodosApp> createState() => _TodosAppState();
}

class _TodosAppState extends State<TodosApp> {
  ThemeMode _mode = ThemeMode.system;

  void _cycle() {
    setState(() {
      _mode = switch (_mode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppDatabaseScope(
      database: widget.database,
      child: ThemeScope(
        mode: _mode,
        cycle: _cycle,
        child: MaterialApp.router(
          title: 'Todos',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _mode,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}