import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/database/database.dart';
import 'core/notifications/notification_service.dart';
import 'features/todos/presentation/reminder_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  final dir = await getApplicationDocumentsDirectory();
  final db = await AppDatabase.open(path: p.join(dir.path, 'todos.db'));
  await rescheduleAllReminders(db);
  runApp(TodosApp(database: db));
}
