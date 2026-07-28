// lib/features/logs/presentation/pages/log_chart_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database_scope.dart';
import '../../../../core/utils/period_calculator.dart';
import '../../data/log_entry_repository.dart';
import '../../domain/log_entry.dart';
import '../../domain/log_item.dart';
import '../bloc/log_bloc.dart';
import '../bloc/log_event.dart';
import '../widgets/log_chart.dart';
import 'log_form_page.dart';

enum _Range { week, month }

typedef LogEntriesLoader = Future<List<LogEntry>> Function(
  String itemId, {
  required DateTime from,
  required DateTime to,
});

class LogChartPage extends StatefulWidget {
  const LogChartPage({super.key, required this.item, this.loadEntries});
  final LogItem item;
  final LogEntriesLoader? loadEntries;
  @override
  State<LogChartPage> createState() => _LogChartPageState();
}

class _LogChartPageState extends State<LogChartPage> {
  _Range _range = _Range.week;
  late Future<List<LogEntry>> _future;
  late LogEntryRepository _entries;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _entries = LogEntryRepository(AppDatabaseScope.of(context));
    _future = _loadDeferred();
    _initialized = true;
  }

  Future<List<LogEntry>> _load() async {
    final (from, to) = _currentRange();
    final loader = widget.loadEntries ?? _entries.listByItemInRange;
    return loader(widget.item.id, from: from, to: to);
  }

  Future<List<LogEntry>> _loadDeferred() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return _load();
  }

  void _reload() {
    setState(() {
      _future = _loadDeferred();
    });
  }

  (DateTime, DateTime) _currentRange() {
    final now = DateTime.now();
    return _range == _Range.week
        ? (PeriodCalculator.weekStart(now), PeriodCalculator.weekEnd(now))
        : (PeriodCalculator.monthStart(now), PeriodCalculator.monthEnd(now));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
        actions: [
          PopupMenuButton<_Range>(
            initialValue: _range,
            onSelected: (r) {
              setState(() => _range = r);
              _reload();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Range.week, child: Text('This week')),
              PopupMenuItem(value: _Range.month, child: Text('This month')),
            ],
          ),
          IconButton(
            tooltip: 'Add entry',
            onPressed: () async {
              final bloc = context.read<LogBloc>();
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: bloc,
                    child: LogFormPage(item: widget.item),
                  ),
                ),
              );
              bloc.add(const LogSubscriptionRequested());
              _reload();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<LogEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (from, to) = _currentRange();
          return _LogHistoryPanel(
            item: widget.item,
            entries: snap.data!,
            rangeStart: from,
            rangeEnd: to,
          );
        },
      ),
    );
  }
}

class _LogHistoryPanel extends StatelessWidget {
  const _LogHistoryPanel({
    required this.item,
    required this.entries,
    required this.rangeStart,
    required this.rangeEnd,
  });

  final LogItem item;
  final List<LogEntry> entries;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No data in this range'));
    }

    final recentEntries = [...entries]
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 260,
          child: LogChart(
            entries: entries,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          ),
        ),
        const SizedBox(height: 24),
        Text('Recent entries', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final entry in recentEntries.take(10))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_formatValue(entry.value, item.unit)),
            subtitle: Text(DateFormat.yMMMd().add_jm().format(entry.loggedAt)),
          ),
      ],
    );
  }

  String _formatValue(double value, String? unit) {
    final unitSuffix = unit == null ? '' : ' $unit';
    return '${value.toStringAsFixed(1)}$unitSuffix';
  }
}
