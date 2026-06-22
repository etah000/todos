// lib/features/logs/presentation/pages/log_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/log_item.dart';
import '../bloc/log_bloc.dart';
import '../bloc/log_event.dart';

class LogFormPage extends StatefulWidget {
  const LogFormPage({super.key, required this.item});
  final LogItem item;

  @override
  State<LogFormPage> createState() => _LogFormPageState();
}

class _LogFormPageState extends State<LogFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _notes = TextEditingController();
  DateTime _when = DateTime.now();

  @override
  void dispose() {
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log ${widget.item.name}'),
        actions: [
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
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Value${widget.item.unit == null ? '' : ' (${widget.item.unit})'}',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Number required';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              minLines: 1, maxLines: 4,
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'When'),
              child: Row(
                children: [
                  Expanded(child: Text(DateFormat.yMMMd().add_jm().format(_when))),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _when,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d == null) return;
                      if (!mounted) return;
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_when),
                      );
                      setState(() {
                        _when = DateTime(d.year, d.month, d.day, t?.hour ?? _when.hour, t?.minute ?? _when.minute);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<LogBloc>().add(LogEntryAdded(
          logItemId: widget.item.id,
          value: double.parse(_value.text),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          loggedAt: _when,
        ));
    Navigator.of(context).pop();
  }
}