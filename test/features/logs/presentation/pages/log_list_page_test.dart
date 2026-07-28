import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/app_database_scope.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/logs/data/log_entry_repository.dart';
import 'package:todos/features/logs/data/log_item_repository.dart';
import 'package:todos/features/logs/domain/log_entry.dart';
import 'package:todos/features/logs/domain/log_item.dart';
import 'package:todos/features/logs/presentation/pages/log_list_page.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('LogListPage', () {
    late AppDatabase db;
    late LogItem item;

    setUp(() async {
      db = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      item = LogItem(
        id: 'weight',
        name: 'weight',
        unit: 'kg',
        createdAt: DateTime(2026, 1, 1),
        archived: false,
      );
      await LogItemRepository(db).insert(item);
      await LogEntryRepository(db).insert(
        LogEntry(
          id: 'entry-1',
          logItemId: item.id,
          value: 75,
          loggedAt: DateTime(2026, 7, 28, 8),
          createdAt: DateTime(2026, 7, 28, 8),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('row add opens entry form and row tap opens history', (
      tester,
    ) async {
      await tester.pumpWidget(
        AppDatabaseScope(
          database: db,
          child: const MaterialApp(home: LogListPage()),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(
        find.text(
          '1 entry · latest: 75.0 kg · ${DateFormat.yMMMd().format(DateTime(2026, 7, 28))}',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Add entry'));
      await tester.pumpAndSettle();
      expect(find.text('Log weight'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('weight'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.text('weight'), findsWidgets);
      expect(find.byTooltip('Add entry'), findsWidgets);
    });
  });
}
