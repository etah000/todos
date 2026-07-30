import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/goal_activity.dart';
import '../../domain/goal_log.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../widgets/log_sheet.dart';
import 'goal_form_page.dart';

class GoalDetailPage extends StatelessWidget {
  const GoalDetailPage({super.key, required this.activity});
  final GoalActivity activity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activity.title),
        actions: [
          IconButton(
            tooltip: 'Edit goal',
            icon: const Icon(Icons.edit),
            onPressed: () {
              final bloc = context.read<GoalBloc>();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc, child: GoalFormPage(existing: activity),
                ),
              ));
            },
          ),
          IconButton(
            tooltip: 'Delete goal',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      floatingActionButton: activity.metric == ActivityMetric.boolean
          ? null
          : FloatingActionButton(
              onPressed: () => _addLog(context),
              child: const Icon(Icons.add),
            ),
      body: BlocBuilder<GoalBloc, GoalState>(
        builder: (context, state) {
          if (state is! GoalsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = state.logsByActivityId[activity.id] ?? const <GoalLog>[];
          final df = DateFormat.yMMMd();
          final snap = activity.progressSnapshot;
          final unitLabel = activity.targetUnit.wire.replaceAll('per_', '');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(activity.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('${_formatCount(activity.targetValue)} / $unitLabel'),
              if (snap != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: snap.percent, minHeight: 4),
                const SizedBox(height: 4),
                Text('${snap.periodsCompleted} of ${snap.periodsElapsed} periods completed'),
              ],
              const SizedBox(height: 24),
              if (activity.metric == ActivityMetric.boolean)
                FilledButton(onPressed: () => _toggleToday(context), child: const Text('Log today')),
              const SizedBox(height: 24),
              Text('Recent logs', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (logs.isEmpty) const Text('No logs yet.'),
              for (final log in logs.take(50))
                ListTile(
                  dense: true,
                  title: Text(_formatCount(log.value)),
                  subtitle: Text(df.format(log.loggedAt)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') context.read<GoalBloc>().add(GoalLogDeleted(log.id));
                      if (v == 'edit') _editLog(context, log);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatCount(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${activity.title}"?'),
        content: const Text('This will permanently delete the goal and every log entry.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<GoalBloc>().add(GoalActivityDeleted(activity.id));
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _addLog(BuildContext context) async {
    final bloc = context.read<GoalBloc>();
    final result = await showLogSheet(context: context, goalActivityId: activity.id);
    if (result == null || !context.mounted) return;
    if (activity.metric == ActivityMetric.count) {
      bloc.add(GoalLogCountAdded(goalActivityId: activity.id, delta: result.value.toInt()));
    } else if (activity.metric == ActivityMetric.duration) {
      bloc.add(GoalLogDurationAdded(goalActivityId: activity.id, seconds: result.value.toInt()));
    }
  }

  Future<void> _editLog(BuildContext context, GoalLog log) async {
    final bloc = context.read<GoalBloc>();
    final result = await showLogSheet(context: context, goalActivityId: activity.id, existing: log);
    if (result == null || !context.mounted) return;
    bloc.add(GoalLogEdited(GoalLog(
      id: log.id,
      goalActivityId: log.goalActivityId,
      value: result.value,
      notes: result.notes,
      loggedAt: result.loggedAt,
      createdAt: log.createdAt,
    )));
  }

  Future<void> _toggleToday(BuildContext context) async {
    final now = DateTime.now();
    final bloc = context.read<GoalBloc>();
    bloc.add(GoalLogBooleanToggled(
      goalActivityId: activity.id,
      periodStart: DateTime(now.year, now.month, now.day),
      periodEnd: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    ));
  }
}