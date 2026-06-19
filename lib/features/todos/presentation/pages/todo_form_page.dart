// lib/features/todos/presentation/pages/todo_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/recurrence.dart';
import '../../domain/todo.dart';
import '../bloc/todo_bloc.dart';
import '../bloc/todo_event.dart';

class TodoFormPage extends StatefulWidget {
  const TodoFormPage({super.key, this.existing});

  final Todo? existing;

  @override
  State<TodoFormPage> createState() => _TodoFormPageState();
}

class _TodoFormPageState extends State<TodoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  DateTime? _dueDate;
  DateTime? _reminderTime;
  Recurrence _recurrence = Recurrence.none;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _title = TextEditingController(text: t?.title ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _dueDate = t?.dueDate;
    _reminderTime = t?.reminderTime;
    _recurrence = t?.recurrence ?? Recurrence.none;
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
        title: Text(isEdit ? 'Edit todo' : 'New todo'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
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
              minLines: 1,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _DatePickerRow(
              label: 'Due date',
              value: _dueDate,
              onChanged: (d) => setState(() => _dueDate = d),
            ),
            const SizedBox(height: 12),
            _DatePickerRow(
              label: 'Reminder',
              value: _reminderTime,
              includeTime: true,
              onChanged: (d) => setState(() => _reminderTime = d),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Recurrence>(
              initialValue: _recurrence,
              decoration: const InputDecoration(labelText: 'Repeats'),
              items: Recurrence.values
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.wire)))
                  .toList(),
              onChanged: (r) => setState(() => _recurrence = r ?? Recurrence.none),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final bloc = context.read<TodoBloc>();
    if (widget.existing == null) {
      bloc.add(TodoCreated(
        title: _title.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        dueDate: _dueDate,
        reminderTime: _reminderTime,
        recurrence: _recurrence,
      ));
    } else {
      bloc.add(TodoUpdated(widget.existing!.copyWith(
        title: _title.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        dueDate: _dueDate,
        reminderTime: _reminderTime,
        recurrence: _recurrence,
      )));
    }
    if (mounted) Navigator.of(context).pop();
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.includeTime = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool includeTime;

  @override
  Widget build(BuildContext context) {
    final df = includeTime ? DateFormat.yMMMd().add_jm() : DateFormat.yMMMd();
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(labelText: label),
            child: Text(value == null ? '—' : df.format(value!)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked == null) return;
            if (includeTime) {
              if (!context.mounted) return;
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
              );
              onChanged(DateTime(picked.year, picked.month, picked.day, t?.hour ?? 9, t?.minute ?? 0));
            } else {
              onChanged(picked);
            }
          },
        ),
        if (value != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }
}
