// lib/features/goals/presentation/widgets/activity_tile.dart
import 'package:flutter/material.dart';

import '../../domain/activity_completion.dart';
import '../../domain/goal_activity.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.activity,
    required this.completion,
    required this.onToggle,
    required this.onDelete,
  });

  final GoalActivity activity;
  final ActivityCompletion? completion;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = completion != null;
    return Dismissible(
      key: ValueKey('activity-${activity.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: CheckboxListTile(
        value: done,
        onChanged: (_) => onToggle(),
        title: Text(
          activity.title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('Repeats ${activity.recurrence.wire}'),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}