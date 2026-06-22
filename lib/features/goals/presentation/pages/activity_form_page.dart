// lib/features/goals/presentation/pages/activity_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../todos/domain/recurrence.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';

class ActivityFormPage extends StatefulWidget {
  const ActivityFormPage({super.key, required this.goalId});
  final String goalId;
  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  Recurrence _recurrence = Recurrence.daily;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New activity'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
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
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<GoalBloc>().add(ActivityCreated(
          goalId: widget.goalId,
          title: _title.text.trim(),
          recurrence: _recurrence,
        ));
    Navigator.of(context).pop();
  }
}