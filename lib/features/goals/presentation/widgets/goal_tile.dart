import 'package:flutter/material.dart';

import '../../domain/goal_activity.dart';
import '../../domain/goal_progress_snapshot.dart';
import '../../domain/goal_target_unit.dart';

class GoalTile extends StatelessWidget {
  const GoalTile({super.key, required this.activity, required this.onTap});

  final GoalActivity activity;
  final ValueChanged<GoalActivity> onTap;

  String _unitLabel(GoalTargetUnit u) => switch (u) {
        GoalTargetUnit.perDay => 'day',
        GoalTargetUnit.perWeek => 'week',
        GoalTargetUnit.perMonth => 'month',
        GoalTargetUnit.perPeriod => 'period',
      };

  String _formatCount(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  String _formatTotal(GoalLifetimeTotal t) {
    if (t is GoalLifetimeTotalBoolean) return '${t.count} days';
    if (t is GoalLifetimeTotalCount) {
      final v = t.total;
      return '${v == v.roundToDouble() ? v.toInt() : v} total';
    }
    if (t is GoalLifetimeTotalDuration) {
      final secs = t.totalSeconds;
      final h = secs ~/ 3600;
      final m = (secs % 3600) ~/ 60;
      if (h > 0) return '${h}h ${m}m';
      if (m > 0) return '${m}m ${secs % 60}s';
      return '${secs}s';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final snap = activity.progressSnapshot ?? GoalProgressSnapshot.empty();
    final unit = _unitLabel(activity.targetUnit);
    final targetChip = '${_formatCount(activity.targetValue)} / $unit';
    final progressText = snap.periodsElapsed == 0
        ? 'not started'
        : '${snap.periodsCompleted} of ${snap.periodsElapsed} periods completed';
    return InkWell(
      onTap: () => onTap(activity),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(activity.title, style: Theme.of(context).textTheme.titleMedium)),
                Chip(label: Text(targetChip)),
                const SizedBox(width: 8),
                Chip(label: Text(_formatTotal(snap.lifetimeTotal))),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: snap.percent, minHeight: 2),
            const SizedBox(height: 4),
            Text(progressText, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
