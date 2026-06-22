// lib/features/goals/presentation/pages/goal_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/goal.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../widgets/activity_tile.dart';
import 'activity_form_page.dart';

class GoalDetailPage extends StatelessWidget {
  const GoalDetailPage({super.key, required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(goal.title)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final bloc = context.read<GoalBloc>();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: ActivityFormPage(goalId: goal.id),
            ),
          ));
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<GoalBloc, GoalState>(
        builder: (context, state) {
          if (state is! GoalsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final acts = state.activitiesByGoalId[goal.id] ?? const [];
          final done = acts.where((a) => state.completionsByActivityId.containsKey(a.id)).length;
          final total = acts.length;
          final progress = total == 0 ? 0.0 : done / total;
          final df = DateFormat.yMMMd();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if ((goal.description ?? '').isNotEmpty) ...[
                Text(goal.description!),
                const SizedBox(height: 12),
              ],
              Text('${df.format(goal.startDate)} → ${df.format(goal.endDate)}'),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Text('$done / $total activities done this period'),
              const SizedBox(height: 16),
              if (acts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No activities yet. Tap + to add one.')),
                )
              else
                ...acts.map((a) => ActivityTile(
                      activity: a,
                      completion: state.completionsByActivityId[a.id],
                      onToggle: () => context.read<GoalBloc>().add(
                            ActivityCompletionToggled(goalId: goal.id, activityId: a.id),
                          ),
                      onDelete: () => context.read<GoalBloc>().add(ActivityDeleted(a.id)),
                    )),
            ],
          );
        },
      ),
    );
  }
}