// lib/features/logs/presentation/widgets/log_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/log_entry.dart';

class LogChart extends StatelessWidget {
  const LogChart({super.key, required this.entries});
  final List<LogEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No data in this range'));
    }
    final sorted = [...entries]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++) FlSpot(i.toDouble(), sorted[i].value),
    ];
    final minY = sorted.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxY = sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.1 + 0.1;
    final df = DateFormat.Md();

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (sorted.length / 4).clamp(1, double.infinity).toDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                return Text(df.format(sorted[i].loggedAt), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            color: Theme.of(context).colorScheme.primary,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}