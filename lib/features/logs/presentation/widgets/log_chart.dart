// lib/features/logs/presentation/widgets/log_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/log_entry.dart';

const _millisecondsPerDay = 86400000;

class LogChart extends StatelessWidget {
  const LogChart({
    super.key,
    required this.entries,
    required this.rangeStart,
    required this.rangeEnd,
  });
  final List<LogEntry> entries;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No data in this range'));
    }
    final sorted = [...entries]
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final spots = <FlSpot>[
      for (final entry in sorted)
        FlSpot(
          entry.loggedAt.difference(rangeStart).inMilliseconds /
              _millisecondsPerDay,
          entry.value,
        ),
    ];
    final minY = sorted.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxY = sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.1 + 0.1;
    const minX = 0.0;
    final maxX =
        rangeEnd.difference(rangeStart).inMilliseconds / _millisecondsPerDay;
    final xSpan = (maxX - minX).abs();
    final df = DateFormat.Md();

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(1),
                softWrap: false,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (xSpan / 4).clamp(1.0, double.infinity),
              getTitlesWidget: (v, _) {
                if (xSpan == 0 || v < minX || v > maxX) {
                  return const SizedBox.shrink();
                }
                final date = rangeStart.add(
                  Duration(milliseconds: (v * _millisecondsPerDay).round()),
                );
                return Text(
                  df.format(date),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 1,
            barWidth: 2,
            color: Theme.of(context).colorScheme.primary,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}
