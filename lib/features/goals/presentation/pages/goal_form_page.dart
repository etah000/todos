import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/category.dart';
import '../../domain/goal_activity.dart';
import '../../domain/goal_target_unit.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../../../todos/domain/recurrence.dart';

class GoalFormPage extends StatefulWidget {
  const GoalFormPage({super.key, this.existing, this.categoryId});
  final GoalActivity? existing;
  final String? categoryId;

  @override
  State<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends State<GoalFormPage> {
  late final TextEditingController _title;
  late final TextEditingController _targetValue;
  late ActivityMetric _metric;
  late Recurrence _recurrence;
  late DateTime _startDate;
  late GoalTargetUnit _targetUnit;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _targetValue = TextEditingController(text: e == null ? '' : e.targetValue.toString());
    _metric = e?.metric ?? ActivityMetric.boolean;
    _recurrence = e?.recurrence ?? Recurrence.daily;
    _startDate = e?.startDate ?? DateTime.now();
    _targetUnit = e?.targetUnit ?? GoalTargetUnit.perDay;
    _selectedCategoryId = widget.categoryId ?? e?.categoryId;
  }

  @override
  void dispose() {
    _title.dispose();
    _targetValue.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    final value = double.tryParse(_targetValue.text.trim()) ?? 1;
    if (title.isEmpty) return;
    final state = context.read<GoalBloc>().state;
    final categories = state is GoalsLoaded ? state.categories : const <Category>[];
    final categoryId = _selectedCategoryId ??
        (widget.existing?.categoryId) ??
        (categories.isNotEmpty ? categories.first.id : null);
    if (categoryId == null) return;
    final bloc = context.read<GoalBloc>();
    if (widget.existing == null) {
      bloc.add(GoalActivityCreated(
        categoryId: categoryId,
        title: title, metric: _metric, recurrence: _recurrence,
        startDate: _startDate, targetValue: value, targetUnit: _targetUnit,
      ));
    } else {
      final existing = widget.existing!;
      bloc.add(GoalActivityUpdated(GoalActivity(
        id: existing.id,
        categoryId: categoryId,
        title: title,
        metric: _metric,
        recurrence: _recurrence,
        recurrenceConfig: existing.recurrenceConfig,
        startDate: _startDate,
        targetValue: value,
        targetUnit: _targetUnit,
        createdAt: existing.createdAt,
        progressSnapshot: existing.progressSnapshot,
      )));
    }
    Navigator.of(context).pop();
  }

  String _unitLabel(GoalTargetUnit u) => switch (u) {
        GoalTargetUnit.perDay => 'per day',
        GoalTargetUnit.perWeek => 'per week',
        GoalTargetUnit.perMonth => 'per month',
        GoalTargetUnit.perPeriod => 'per period',
      };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GoalBloc>().state;
    final categories = state is GoalsLoaded ? state.categories : const <Category>[];
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Goal' : 'New Goal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            DropdownButtonFormField<ActivityMetric>(
              value: _metric,
              decoration: const InputDecoration(labelText: 'Metric'),
              items: const [
                DropdownMenuItem(value: ActivityMetric.boolean, child: Text('Yes / No')),
                DropdownMenuItem(value: ActivityMetric.count, child: Text('Counter')),
                DropdownMenuItem(value: ActivityMetric.duration, child: Text('Duration')),
              ],
              onChanged: (v) => setState(() => _metric = v ?? _metric),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Recurrence>(
              value: _recurrence,
              decoration: const InputDecoration(labelText: 'Recording cadence'),
              items: const [
                DropdownMenuItem(value: Recurrence.none, child: Text('None')),
                DropdownMenuItem(value: Recurrence.daily, child: Text('Daily')),
                DropdownMenuItem(value: Recurrence.weekly, child: Text('Weekly')),
                DropdownMenuItem(value: Recurrence.monthly, child: Text('Monthly')),
              ],
              onChanged: (v) => setState(() => _recurrence = v ?? _recurrence),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(_startDate.toIso8601String().substring(0, 10)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetValue,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target value'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GoalTargetUnit>(
              value: _targetUnit,
              decoration: const InputDecoration(labelText: 'Target unit'),
              items: [
                for (final u in GoalTargetUnit.values)
                  DropdownMenuItem(value: u, child: Text(_unitLabel(u))),
              ],
              onChanged: (v) => setState(() => _targetUnit = v ?? _targetUnit),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in categories)
                  DropdownMenuItem(value: c.id, child: Text(c.title)),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: Text(isEdit ? 'Save' : 'Add')),
          ],
        ),
      ),
    );
  }
}
