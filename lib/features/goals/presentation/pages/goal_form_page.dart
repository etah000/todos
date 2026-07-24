// lib/features/goals/presentation/pages/goal_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/goal.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';

class GoalFormPage extends StatefulWidget {
  const GoalFormPage({super.key, this.existing});
  final Goal? existing;
  @override
  State<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends State<GoalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _description.text = e.description ?? '';
      _start = e.startDate;
      _end = e.endDate;
    } else {
      _start = DateTime.now();
      _end = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit goal' : 'New goal'),
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
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 1, maxLines: 4,
            ),
            const SizedBox(height: 16),
            _DateRow(label: 'Start', value: _start, onChanged: (d) => setState(() => _start = d)),
            const SizedBox(height: 8),
            _DateRow(label: 'End', value: _end, onChanged: (d) => setState(() => _end = d)),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (!_end.isAfter(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End must be after start')),
      );
      return;
    }
    final bloc = context.read<GoalBloc>();
    final existing = widget.existing;
    if (existing == null) {
      bloc.add(
        GoalCreated(
          title: _title.text.trim(),
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          startDate: _start,
          endDate: _end,
        ),
      );
    } else {
      final updated = existing.copyWith(
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        startDate: _start,
        endDate: _end,
      );
      bloc.add(GoalUpdated(updated));
    }
    Navigator.of(context).pop();
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(labelText: label),
            child: Text(DateFormat.yMMMd().format(value)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) onChanged(picked);
          },
        ),
      ],
    );
  }
}