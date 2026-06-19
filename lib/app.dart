import 'package:flutter/material.dart';

import 'core/database/app_database_scope.dart';
import 'core/database/database.dart';
import 'core/theme/app_theme.dart';
import 'routes.dart';

class TodosApp extends StatelessWidget {
  const TodosApp({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return AppDatabaseScope(
      database: database,
      child: MaterialApp.router(
        title: 'Todos',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: appRouter,
      ),
    );
  }
}
