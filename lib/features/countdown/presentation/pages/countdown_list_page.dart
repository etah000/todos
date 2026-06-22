// lib/features/countdown/presentation/pages/countdown_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database_scope.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/countdown_repository.dart';
import '../bloc/countdown_bloc.dart';
import '../bloc/countdown_event.dart';
import '../bloc/countdown_state.dart';
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
      appBar: AppBar(title: const Text('Countdown')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final bloc = context.read<CountdownBloc>();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BlocProvider.value(value: bloc, child: const CountdownFormPage()),
          ));
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
                  trailing: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: days < 0 ? Theme.of(context).disabledColor : null,
                        ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}