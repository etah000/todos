// lib/features/logs/presentation/pages/log_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database_scope.dart';
import '../../../../core/theme/theme_scope.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/log_entry_repository.dart';
import '../../data/log_item_repository.dart';
import '../../domain/log_entry.dart';
import '../../domain/log_item.dart';
import '../bloc/log_bloc.dart';
import '../bloc/log_event.dart';
import '../bloc/log_state.dart';
import 'log_chart_page.dart';
import 'log_form_page.dart';

class LogListPage extends StatelessWidget {
  const LogListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return BlocProvider(
      create: (_) => LogBloc(
        itemRepo: LogItemRepository(db),
        entryRepo: LogEntryRepository(db),
        uuid: const Uuid(),
      )..add(const LogSubscriptionRequested()),
      child: const _LogListView(),
    );
  }
}

class _LogListView extends StatelessWidget {
  const _LogListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            tooltip: 'Add item',
            onPressed: () => _openItemForm(context),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Cycle theme',
            onPressed: () => ThemeScope.of(context).cycle(),
            icon: const Icon(Icons.brightness_6),
          ),
        ],
      ),
      body: BlocBuilder<LogBloc, LogState>(
        builder: (context, state) {
          if (state is LogLoading || state is LogInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LogErrorState) {
            return Center(child: Text('Error: ${state.message}'));
          }
          final loaded = state as LogLoaded;
          if (loaded.items.isEmpty) {
            return const EmptyState(
              title: 'No log items',
              subtitle: 'Add one (e.g. "weight") to start tracking.',
              icon: Icons.show_chart,
            );
          }
          return ListView.separated(
            itemCount: loaded.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _LogItemTile(
              item: loaded.items[i],
              entries: loaded.entriesByItemId[loaded.items[i].id] ?? const [],
            ),
          );
        },
      ),
    );
  }

  void _openItemForm(BuildContext context) {
    final bloc = context.read<LogBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const _NewLogItemSheet(),
      ),
    );
  }
}

class _LogItemTile extends StatelessWidget {
  const _LogItemTile({required this.item, required this.entries});
  final LogItem item;
  final List<LogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final last = entries.isEmpty ? '—' : entries.first.value.toStringAsFixed(1);
    return ListTile(
      title: Text(item.name),
      subtitle: Text('${entries.length} entries · last: $last${item.unit == null ? '' : ' ${item.unit}'}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Add entry',
            icon: const Icon(Icons.add),
            onPressed: () {
              final bloc = context.read<LogBloc>();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BlocProvider.value(value: bloc, child: LogFormPage(item: item)),
              ));
            },
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => LogChartPage(item: item),
        ));
      },
      onLongPress: () {
        final bloc = context.read<LogBloc>();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BlocProvider.value(value: bloc, child: LogFormPage(item: item)),
        ));
      },
    );
  }
}

class _NewLogItemSheet extends StatefulWidget {
  const _NewLogItemSheet();
  @override
  State<_NewLogItemSheet> createState() => _NewLogItemSheetState();
}

class _NewLogItemSheetState extends State<_NewLogItemSheet> {
  final _name = TextEditingController();
  final _unit = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('New log item', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 8),
          TextField(controller: _unit, decoration: const InputDecoration(labelText: 'Unit (optional)')),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              if (_name.text.trim().isEmpty) return;
              context.read<LogBloc>().add(LogItemCreated(
                    name: _name.text.trim(),
                    unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
                  ));
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}