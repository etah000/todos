import 'package:flutter/material.dart';

import '../../domain/goal_log.dart';

Future<GoalLog?> showLogSheet({
  required BuildContext context,
  required String goalActivityId,
  GoalLog? existing,
}) {
  return showModalBottomSheet<GoalLog>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => LogSheet(goalActivityId: goalActivityId, existing: existing),
  );
}

class LogSheet extends StatefulWidget {
  const LogSheet({super.key, required this.goalActivityId, this.existing});
  final String goalActivityId;
  final GoalLog? existing;

  @override
  State<LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<LogSheet> {
  late final TextEditingController _value;
  late final TextEditingController _notes;
  late DateTime _loggedAt;

  @override
  void initState() {
    super.initState();
    _value = TextEditingController(
      text: widget.existing == null
          ? ''
          : (widget.existing!.value == widget.existing!.value.roundToDouble()
              ? widget.existing!.value.toInt().toString()
              : widget.existing!.value.toString()),
    );
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _loggedAt = widget.existing?.loggedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_value.text.trim());
    if (value == null) return;
    final log = GoalLog(
      id: widget.existing?.id ?? 'new',
      goalActivityId: widget.goalActivityId,
      value: value,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      loggedAt: _loggedAt,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(log);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.existing == null ? 'Log entry' : 'Edit entry',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Value'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Logged at'),
            subtitle: Text(_loggedAt.toIso8601String().substring(0, 16)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _loggedAt,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) setState(() => _loggedAt = picked);
            },
          ),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('Save')),
        ],
      ),
    );
  }
}
