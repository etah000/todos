import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todos/features/logs/domain/log_entry.dart';
import 'package:todos/features/logs/presentation/widgets/log_chart.dart';

void main() {
  group('LogChart', () {
    testWidgets(
        'uses elapsed logged time for x values instead of entry indexes', (
      tester,
    ) async {
      final rangeStart = DateTime(2026, 7, 1);
      final rangeEnd = DateTime(2026, 7, 31, 23, 59);
      final entries = [
        LogEntry(
          id: 'late',
          logItemId: 'weight',
          value: 78,
          loggedAt: DateTime(2026, 7, 28),
          createdAt: DateTime(2026, 7, 28),
        ),
        LogEntry(
          id: 'early',
          logItemId: 'weight',
          value: 75,
          loggedAt: DateTime(2026, 7, 1),
          createdAt: DateTime(2026, 7, 1),
        ),
        LogEntry(
          id: 'middle',
          logItemId: 'weight',
          value: 76,
          loggedAt: DateTime(2026, 7, 2),
          createdAt: DateTime(2026, 7, 2),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: LogChart(
                entries: entries,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
              ),
            ),
          ),
        ),
      );

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final spots = chart.data.lineBarsData.single.spots;

      expect(spots.map((spot) => spot.x), [0.0, 1.0, 27.0]);
      expect(chart.data.minX, 0);
      expect(chart.data.maxX, closeTo(30.999, 0.01));
    });

    testWidgets('renders a single entry without curved interpolation', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: LogChart(
                entries: [
                  LogEntry(
                    id: 'single',
                    logItemId: 'weight',
                    value: 75,
                    loggedAt: DateTime(2026, 7, 28),
                    createdAt: DateTime(2026, 7, 28),
                  ),
                ],
                rangeStart: DateTime(2026, 7, 27),
                rangeEnd: DateTime(2026, 8, 2, 23, 59),
              ),
            ),
          ),
        ),
      );

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.single.isCurved, isFalse);
    });

    testWidgets('renders inside a scrolling detail layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(
                  height: 260,
                  child: LogChart(
                    entries: [
                      LogEntry(
                        id: 'single',
                        logItemId: 'weight',
                        value: 75,
                        loggedAt: DateTime(2026, 7, 28, 8),
                        createdAt: DateTime(2026, 7, 28, 8),
                      ),
                    ],
                    rangeStart: DateTime(2026, 7, 27),
                    rangeEnd: DateTime(2026, 8, 2, 23, 59),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Recent entries'),
                const ListTile(title: Text('75.0 kg')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Recent entries'), findsOneWidget);
      expect(find.text('75.0 kg'), findsOneWidget);
    });
  });
}
