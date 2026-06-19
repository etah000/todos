// lib/features/todos/presentation/widgets/todo_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/recurrence.dart';
import '../../domain/todo.dart';
import '../../domain/todo_completion.dart';

class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.completion,
    required this.onToggleComplete,
    required this.onTap,
    required this.onDelete,
  });

  final Todo todo;
  final TodoCompletion? completion;
  final VoidCallback onToggleComplete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = completion != null;
    final df = DateFormat.yMMMd();
    final subtitle = _subtitle(df);

    return Dismissible(
      key: ValueKey('todo-${todo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Checkbox(
          value: done,
          onChanged: (_) => onToggleComplete(),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : null,
            color: done ? Theme.of(context).disabledColor : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _subtitle(DateFormat df) {
    final parts = <String>[];
    if (todo.dueDate != null) parts.add('Due ${df.format(todo.dueDate!)}');
    if (todo.recurrence != Recurrence.none) {
      parts.add('Repeats ${todo.recurrence.wire}');
    }
    if (todo.reminderTime != null) {
      parts.add('Reminder ${DateFormat.jm().format(todo.reminderTime!)}');
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}
