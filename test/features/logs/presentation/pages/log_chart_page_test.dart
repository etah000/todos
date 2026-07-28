import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todos/core/database/app_database_scope.dart';
import 'package:todos/core/database/database.dart';
import 'package:todos/features/logs/domain/log_entry.dart';
import 'package:todos/features/logs/domain/log_item.dart';
import 'package:todos/features/logs/presentation/pages/log_chart_page.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('LogChartPage', () {
    late AppDatabase db;

    setUp(() async {
      db = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('loads entries after inherited database is available', (
      tester,
    ) async {
      final item = LogItem(
        id: 'weight',
        name: 'Weight',
        createdAt: DateTime(2026, 1, 1),
        archived: false,
      );

      await tester.pumpWidget(
        AppDatabaseScope(
          database: db,
          child: MaterialApp(
            home: LogChartPage(item: item),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.text('No data in this range'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows recent entries for populated current week range', (
      tester,
    ) async {
      final now = DateTime.now();
      final item = LogItem(
        id: 'weight',
        name: 'Weight',
        unit: 'kg',
        createdAt: DateTime(2026, 1, 1),
        archived: false,
      );
      final seededEntries = [
        LogEntry(
          id: 'entry-1',
          logItemId: item.id,
          value: 75,
          loggedAt: DateTime(now.year, now.month, now.day, 8),
          createdAt: now,
        ),
        LogEntry(
          id: 'entry-2',
          logItemId: item.id,
          value: 76,
          loggedAt: DateTime(now.year, now.month, now.day, 20),
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(
        AppDatabaseScope(
          database: db,
          child: MaterialApp(
            home: LogChartPage(
              item: item,
              loadEntries: (_, {required from, required to}) async =>
                  seededEntries,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Recent entries'), findsOneWidget);
      expect(find.text('76.0 kg'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
