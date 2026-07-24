// lib/features/todos/presentation/pages/todo_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database_scope.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/theme_scope.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/finished_todo_repository.dart';
import '../../data/todo_completion_repository.dart';
import '../../data/todo_repository.dart';
import '../../domain/finished_todo.dart';
import '../../domain/todo.dart';
import '../bloc/todo_bloc.dart';
import '../bloc/todo_event.dart';
import '../bloc/todo_state.dart';
import '../widgets/todo_tile.dart';
import '../bloc/notification_scheduler.dart';
import 'todo_form_page.dart';

class TodoListPage extends StatelessWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return BlocProvider(
      create: (_) => TodoBloc(
        todoRepo: TodoRepository(db),
        completionRepo: TodoCompletionRepository(db),
        finishedRepo: FinishedTodoRepository(db),
        uuid: const Uuid(),
        notifications: const SystemNotificationScheduler(),
      )..add(const TodosSubscriptionRequested()),
      child: const _TodoListView(),
    );
  }
}

class _TodoListView extends StatelessWidget {
  const _TodoListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        actions: [
          IconButton(
            tooltip: 'Cycle theme',
            onPressed: () => ThemeScope.of(context).cycle(),
            icon: const Icon(Icons.brightness_6),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: BlocListener<TodoBloc, TodoState>(
        listener: (context, state) {
          if (state is! TodosLoaded) return;
          final payload = NotificationService.instance.consumePendingTap();
          if (payload == null) return;
          const prefix = 'todo:';
          if (!payload.startsWith(prefix)) return;
          final id = payload.substring(prefix.length);
          final match = state.items.where((t) => t.id == id).toList();
          if (match.isEmpty) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            _openForm(context, existing: match.first);
          });
        },
        child: BlocBuilder<TodoBloc, TodoState>(
          builder: (context, state) {
            if (state is TodosLoading || state is TodosInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TodosError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            final loaded = state as TodosLoaded;
            if (loaded.items.isEmpty && loaded.history.isEmpty) {
              return const EmptyState(
                title: 'No todos yet',
                subtitle: 'Tap + to add your first todo.',
                icon: Icons.check_circle_outline,
              );
            }
            return ListView(
              children: [
                if (loaded.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Text(
                      'No active todos. All caught up!',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final todo in loaded.items)
                    TodoTile(
                      todo: todo,
                      completion: loaded.completionsByTodoId[todo.id],
                      onToggleComplete: () => context
                          .read<TodoBloc>()
                          .add(TodoCompletionToggled(todo.id)),
                      onTap: () => _openForm(context, existing: todo),
                      onDelete: () =>
                          context.read<TodoBloc>().add(TodoDeleted(todo.id)),
                    ),
                if (loaded.history.isNotEmpty) _HistorySection(history: loaded.history),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openForm(BuildContext context, {Todo? existing}) {
    final bloc = context.read<TodoBloc>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: TodoFormPage(existing: existing),
      ),
    ));
  }
}

class _HistorySection extends StatefulWidget {
  const _HistorySection({required this.history});
  final List<FinishedTodo> history;

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_jm();
    final visible = _expanded ? widget.history : widget.history.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.history, size: 18, color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 6),
                Text(
                  'History (last 7 days) — ${widget.history.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                if (widget.history.length > 3) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(_expanded ? 'Show less' : 'Show all'),
                  ),
                ],
              ],
            ),
          ),
          for (final h in visible)
            ListTile(
              dense: true,
              leading: const Icon(Icons.check, size: 18),
              title: Text(
                h.title,
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
              subtitle: Text(df.format(h.completedAt)),
            ),
        ],
      ),
    );
  }
}
