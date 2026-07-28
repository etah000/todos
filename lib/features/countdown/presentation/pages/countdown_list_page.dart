// lib/features/countdown/presentation/pages/countdown_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database_scope.dart';
import '../../../../core/theme/theme_scope.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/countdown_repository.dart';
import '../bloc/countdown_bloc.dart';
import '../bloc/countdown_event.dart';
import '../bloc/countdown_state.dart';
import '../../domain/countdown_event.dart' as domain;
import 'countdown_form_page.dart';

class CountdownListPage extends StatelessWidget {
  const CountdownListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return BlocProvider(
      create: (_) => CountdownBloc(
        repo: CountdownRepository(db),
        uuid: const Uuid(),
      )..add(const CountdownSubscriptionRequested()),
      child: const _CountdownListView(),
    );
  }
}

class _CountdownListView extends StatelessWidget {
  const _CountdownListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Countdown'),
        actions: [
          IconButton(
            tooltip: 'Cycle theme',
            onPressed: () => ThemeScope.of(context).cycle(),
            icon: const Icon(Icons.brightness_6),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final bloc = context.read<CountdownBloc>();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: const CountdownFormPage(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<CountdownBloc, CountdownState>(
        builder: (context, state) {
          if (state is CountdownLoading || state is CountdownInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CountdownErrorState) {
            return Center(child: Text('Error: ${state.message}'));
          }
          final loaded = state as CountdownLoaded;
          if (loaded.events.isEmpty) {
            return const EmptyState(
              title: 'No countdowns',
              subtitle: 'Add one to see days remaining.',
              icon: Icons.timer_outlined,
            );
          }
          return ListView.separated(
            itemCount: loaded.events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = loaded.events[i];
              final days = e.daysRemaining();
              final label = days == 0
                  ? 'Today'
                  : days > 0
                      ? '$days day${days == 1 ? '' : 's'} left'
                      : '${-days} day${days == -1 ? '' : 's'} ago';
              final colorScheme = Theme.of(context).colorScheme;
              final daysColor = days < 0
                  ? colorScheme.error
                  : days == 0
                      ? colorScheme.primary
                      : Colors.green.shade700;
              return Dismissible(
                key: ValueKey('countdown-${e.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: Colors.red,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => context.read<CountdownBloc>().add(CountdownDeleted(e.id)),
                child: ListTile(
                  title: Text(e.title),
                  subtitle: Text(DateFormat.yMMMd().format(e.targetDate)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: daysColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, e),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    final bloc = context.read<CountdownBloc>();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: bloc,
                          child: CountdownFormPage(existing: e),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, domain.CountdownEvent e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${e.title}"?'),
        content: const Text(
          'This will permanently delete the countdown.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<CountdownBloc>().add(CountdownDeleted(e.id));
  }
}