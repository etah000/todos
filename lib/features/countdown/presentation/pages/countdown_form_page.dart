// lib/features/countdown/presentation/pages/countdown_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/countdown_event.dart' as domain;
import '../bloc/countdown_bloc.dart';
import '../bloc/countdown_event.dart';

class CountdownFormPage extends StatefulWidget {
  const CountdownFormPage({super.key, this.existing});
  final domain.CountdownEvent? existing;
  @override
  State<CountdownFormPage> createState() => _CountdownFormPageState();
}

class _CountdownFormPageState extends State<CountdownFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _target;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _notes.text = e.notes ?? '';
      _target = e.targetDate;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit countdown' : 'New countdown'),
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
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              minLines: 1, maxLines: 4,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Target date'),
                    child: Text(_target == null ? '—' : DateFormat.yMMMd().format(_target!)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _target ?? DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _target = picked);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a target date')),
      );
      return;
    }
    final bloc = context.read<CountdownBloc>();
    final existing = widget.existing;
    if (existing == null) {
      bloc.add(
        CountdownCreated(
          title: _title.text.trim(),
          targetDate: _target,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ),
      );
    } else {
      final updated = existing.copyWith(
        title: _title.text.trim(),
        targetDate: _target,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      bloc.add(CountdownUpdated(updated));
    }
    Navigator.of(context).pop();
  }
}