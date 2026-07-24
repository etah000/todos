// lib/features/goals/presentation/pages/goal_detail_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database_scope.dart';
import '../../../../core/utils/period_calculator.dart';
import '../../data/activity_completion_repository.dart';
import '../../domain/activity_completion.dart';
import '../../domain/goal.dart';
import '../../domain/goal_activity.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../widgets/activity_tile.dart';
import 'activity_form_page.dart';
import 'goal_form_page.dart';

class GoalDetailPage extends StatelessWidget {
  const GoalDetailPage({super.key, required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
        actions: [
          IconButton(
            tooltip: 'Edit goal',
            onPressed: () {
              final bloc = context.read<GoalBloc>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: bloc,
                    child: GoalFormPage(existing: goal),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
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
          final df = DateFormat.yMMMd();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if ((goal.description ?? '').isNotEmpty) ...[
                Text(goal.description!),
                const SizedBox(height: 12),
              ],
              Text('${df.format(goal.startDate)} → ${df.format(goal.endDate)}'),
              const SizedBox(height: 16),
              if (acts.isNotEmpty) ...[
                Text('Weekly progress',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                WeeklyProgressCard(activityIds: acts.map((a) => a.id).toList()),
                const SizedBox(height: 16),
              ],
              _ActivitiesExpansion(
                goalId: goal.id,
                activities: acts,
                completionsByActivityId: state.completionsByActivityId,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActivitiesExpansion extends StatelessWidget {
  const _ActivitiesExpansion({
    required this.goalId,
    required this.activities,
    required this.completionsByActivityId,
  });

  final String goalId;
  final List<GoalActivity> activities;
  final Map<String, ActivityCompletion> completionsByActivityId;

  @override
  Widget build(BuildContext context) {
    final done = activities
        .where((a) => completionsByActivityId.containsKey(a.id))
        .length;
    final total = activities.length;
    return Theme(
      // Strip the default ExpansionTile divider + rounded border so the
      // child tiles look like normal list rows.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        title:
            Text('Activities', style: Theme.of(context).textTheme.titleMedium),
        subtitle:
            Text(total == 0 ? 'None yet' : '$done / $total done this period'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Add activity',
              icon: const Icon(Icons.add),
              onPressed: () {
                final bloc = context.read<GoalBloc>();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: bloc,
                    child: ActivityFormPage(goalId: goalId),
                  ),
                ));
              },
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child:
                  Center(child: Text('No activities yet. Tap + to add one.')),
            )
          else
            ...activities.map((a) {
              final isBoolean = a.metric == ActivityMetric.boolean;
              return Column(
                children: [
                  ActivityTile(
                    activity: a,
                    completion: completionsByActivityId[a.id],
                    onToggle: () {
                      if (isBoolean) {
                        context.read<GoalBloc>().add(
                              ActivityCompletionToggled(
                                  goalId: goalId, activityId: a.id),
                            );
                      }
                    },
                    onDelete: () =>
                        context.read<GoalBloc>().add(ActivityDeleted(a.id)),
                    onEdit: () => _openActivityEdit(context, a),
                    onLogCount: (n) => context.read<GoalBloc>().add(
                          ActivityCountLogged(activityId: a.id, delta: n),
                        ),
                    onLogDuration: (s) => context.read<GoalBloc>().add(
                          ActivityDurationLogged(activityId: a.id, seconds: s),
                        ),
                  ),
                  if (isBoolean)
                    LinearProgressIndicator(
                      value:
                          completionsByActivityId.containsKey(a.id) ? 1.0 : 0.0,
                      minHeight: 2,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  void _openActivityEdit(BuildContext context, GoalActivity a) {
    final bloc = context.read<GoalBloc>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ActivityFormPage(goalId: goalId, existing: a),
      ),
    ));
  }
}

class WeeklyProgressCard extends StatelessWidget {
  const WeeklyProgressCard({super.key, required this.activityIds});
  final List<String> activityIds;

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    final repo = ActivityCompletionRepository(db);
    final now = DateTime.now();
    final from = PeriodCalculator.weekStart(now);
    final to =
        PeriodCalculator.weekEnd(now).add(const Duration(milliseconds: 1));
    return FutureBuilder<List<ActivityCompletion>>(
      future: repo.listByActivitiesInRange(activityIds, from: from, to: to),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final counts = _dailyCounts(snap.data!, from, to);
        final maxY = counts
            .fold<int>(0, (m, c) => c > m ? c : m)
            .clamp(1, 9999)
            .toDouble();
        return SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY + 0.5,
              barTouchData: BarTouchData(enabled: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= 7) return const SizedBox.shrink();
                      final day = from.add(Duration(days: i));
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat.E().format(day),
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < 7; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: counts[i].toDouble(),
                        color: Theme.of(context).colorScheme.primary,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Index 0 = [from] (Monday), index 6 = Sunday. De-duplicates by activity
  /// within a day so the bar shows "distinct activities completed", not raw
  /// tap count.
  static List<int> _dailyCounts(
      List<ActivityCompletion> cs, DateTime from, DateTime to) {
    final out = List<int>.filled(7, 0);
    final perDay = List<Set<String>>.generate(7, (_) => <String>{});
    for (final c in cs) {
      final t = c.completedAt;
      if (t.isBefore(from) || !t.isBefore(to)) continue;
      final i = (t.difference(from).inHours / 24).floor();
      if (i < 0 || i > 6) continue;
      perDay[i].add(c.activityId);
    }
    for (var i = 0; i < 7; i++) {
      out[i] = perDay[i].length;
    }
    return out;
  }
}
