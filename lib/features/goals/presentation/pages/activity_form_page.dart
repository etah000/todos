// lib/features/goals/presentation/pages/activity_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../todos/domain/recurrence.dart';
import '../../domain/goal_activity.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';

class ActivityFormPage extends StatefulWidget {
  const ActivityFormPage({super.key, required this.goalId, this.existing});
  final String goalId;
  final GoalActivity? existing;
  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  Recurrence _recurrence = Recurrence.daily;
  ActivityMetric _metric = ActivityMetric.boolean;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _recurrence = e.recurrence;
      _metric = e.metric;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String _metricLabel(ActivityMetric m) {
    switch (m) {
      case ActivityMetric.boolean: return 'Yes / no (done this period)';
      case ActivityMetric.count: return 'Count (e.g. 10 push-ups)';
      case ActivityMetric.duration: return 'Time (e.g. study ≥ 3 h/week)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit activity' : 'New activity'),
        actions: [TextButton(onPressed: _save, style: TextButton.styleFrom(foregroundColor: Theme.of(context).appBarTheme.foregroundColor), child: const Text('Save'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Recurrence>(
              initialValue: _recurrence,
              decoration: const InputDecoration(labelText: 'Repeats'),
              items: Recurrence.values
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.wire)))
                  .toList(),
              onChanged: (r) => setState(() => _recurrence = r ?? Recurrence.daily),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ActivityMetric>(
              initialValue: _metric,
              decoration: const InputDecoration(labelText: 'Measurement'),
              items: ActivityMetric.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(_metricLabel(m))))
                  .toList(),
              onChanged: (m) => setState(() => _metric = m ?? ActivityMetric.boolean),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<GoalBloc>();
    final existing = widget.existing;
    if (existing == null) {
      bloc.add(ActivityCreated(
        goalId: widget.goalId,
        title: _title.text.trim(),
        recurrence: _recurrence,
        metric: _metric,
      ));
    } else {
      bloc.add(ActivityUpdated(existing.copyWith(
        title: _title.text.trim(),
        recurrence: _recurrence,
        metric: _metric,
      )));
    }
    Navigator.of(context).pop();
  }
}
