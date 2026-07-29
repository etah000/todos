import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/category.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';

class CategoryFormPage extends StatefulWidget {
  const CategoryFormPage({super.key, this.existing});
  final Category? existing;

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  late final TextEditingController _title;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _description = TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final desc = _description.text.trim();
    final bloc = context.read<GoalBloc>();
    if (widget.existing == null) {
      bloc.add(CategoryCreated(
        title: title,
        description: desc.isEmpty ? null : desc,
      ));
    } else {
      bloc.add(CategoryUpdated(widget.existing!.copyWith(
        title: title,
        description: desc.isEmpty ? null : desc,
      )));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Category' : 'New Category')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: _description, decoration: const InputDecoration(labelText: 'Description (optional)')),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: Text(isEdit ? 'Save' : 'Add')),
          ],
        ),
      ),
    );
  }
}