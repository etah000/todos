// lib/features/goals/presentation/pages/goal_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database_scope.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/activity_completion_repository.dart';
import '../../data/goal_activity_repository.dart';
import '../../data/goal_repository.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import 'goal_detail_page.dart';
import 'goal_form_page.dart';

class GoalListPage extends StatelessWidget {
  const GoalListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return BlocProvider(
      create: (_) => GoalBloc(
        goalRepo: GoalRepository(db),
        activityRepo: GoalActivityRepository(db),
        completionRepo: ActivityCompletionRepository(db),
        uuid: const Uuid(),
      )..add(const GoalsSubscriptionRequested()),
      child: const _GoalListView(),
    );
  }
}

class _GoalListView extends StatelessWidget {
  const _GoalListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<GoalBloc, GoalState>(
        builder: (context, state) {
          if (state is GoalLoading || state is GoalInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GoalErrorState) {
            return Center(child: Text('Error: ${state.message}'));
          }
          final loaded = state as GoalsLoaded;
          if (loaded.goals.isEmpty) {
            return const EmptyState(
              title: 'No goals yet',
              subtitle: 'Tap + to set a goal with a time range and activities.',
              icon: Icons.flag_outlined,
            );
          }
          return ListView.separated(
            itemCount: loaded.goals.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final g = loaded.goals[i];
              final acts = loaded.activitiesByGoalId[g.id] ?? const [];
              final done = acts.where((a) => loaded.completionsByActivityId.containsKey(a.id)).length;
              final df = DateFormat.yMMMd();
              return Dismissible(
                key: ValueKey('goal-${g.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: Colors.red,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => context.read<GoalBloc>().add(GoalDeleted(g.id)),
                child: ListTile(
                  title: Text(g.title),
                  subtitle: Text('${df.format(g.startDate)} – ${df.format(g.endDate)}  ·  $done/${acts.length} done'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<GoalBloc>(),
                      child: GoalDetailPage(goal: g),
                    ),
                  )),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context) {
    final bloc = context.read<GoalBloc>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(value: bloc, child: const GoalFormPage()),
    ));
  }
}