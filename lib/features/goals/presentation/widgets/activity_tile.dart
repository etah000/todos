// lib/features/goals/presentation/widgets/activity_tile.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/activity_completion.dart';
import '../../domain/goal_activity.dart';

class ActivityTile extends StatefulWidget {
  const ActivityTile({
    super.key,
    required this.activity,
    required this.completion,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onLogCount,
    required this.onLogDuration,
  });

  final GoalActivity activity;
  final ActivityCompletion? completion;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final void Function(int delta) onLogCount;
  final void Function(int seconds) onLogDuration;

  @override
  State<ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<ActivityTile> {
  final _countController = TextEditingController();
  DateTime? _timerStart;

  @override
  void dispose() {
    _countController.dispose();
    _timerStart = null;
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    return Dismissible(
      key: ValueKey('activity-${a.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: ListTile(
        onTap: widget.onEdit,
        title: Text(a.title),
        subtitle: Text('Repeats ${a.recurrence.wire}'),
        trailing: _trailing(),
      ),
    );
  }

  Widget _trailing() {
    switch (widget.activity.metric) {
      case ActivityMetric.boolean:
        final done = widget.completion != null;
        return Checkbox(
          value: done,
          onChanged: (_) => widget.onToggle(),
        );
      case ActivityMetric.count:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.activity.totalCount}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '+N',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 4),
            FilledButton.tonal(
              onPressed: () {
                final n = int.tryParse(_countController.text.trim());
                if (n == null || n == 0) return;
                widget.onLogCount(n);
                _countController.clear();
              },
              child: const Text('Log'),
            ),
          ],
        );
      case ActivityMetric.duration:
        final running = _timerStart != null;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDuration(widget.activity.totalSeconds),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () {
                if (running) {
                  final secs = DateTime.now().difference(_timerStart!).inSeconds;
                  setState(() => _timerStart = null);
                  widget.onLogDuration(secs);
                } else {
                  setState(() => _timerStart = DateTime.now());
                }
              },
              child: Text(running ? 'Stop' : 'Start'),
            ),
          ],
        );
    }
  }
}
