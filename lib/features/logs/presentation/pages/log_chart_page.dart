// lib/features/logs/presentation/pages/log_chart_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database_scope.dart';
import '../../../../core/utils/period_calculator.dart';
import '../../data/log_entry_repository.dart';
import '../../domain/log_entry.dart';
import '../../domain/log_item.dart';
import '../bloc/log_bloc.dart';
import '../widgets/log_chart.dart';
import 'log_form_page.dart';

enum _Range { week, month }

class LogChartPage extends StatefulWidget {
  const LogChartPage({super.key, required this.item});
  final LogItem item;
  @override
  State<LogChartPage> createState() => _LogChartPageState();
}

class _LogChartPageState extends State<LogChartPage> {
  _Range _range = _Range.week;
  late Future<List<LogEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<LogEntry>> _load() async {
    final repo = LogEntryRepository(AppDatabaseScope.of(context));
    final now = DateTime.now();
    final (from, to) = _range == _Range.week
        ? (PeriodCalculator.weekStart(now), PeriodCalculator.weekEnd(now))
        : (PeriodCalculator.monthStart(now), PeriodCalculator.monthEnd(now));
    return repo.listByItemInRange(widget.item.id, from: from, to: to);
  }

  void _reload() => setState(() => _future = _load());

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
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BlocProvider.value(value: bloc, child: LogFormPage(item: widget.item)),
              ));
              _reload();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<LogEntry>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return Padding(
            padding: const EdgeInsets.all(16),
            child: LogChart(entries: snap.data!),
          );
        },
      ),
    );
  }
}