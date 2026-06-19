// lib/features/todos/presentation/pages/todo_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database_scope.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/todo_completion_repository.dart';
import '../../data/todo_repository.dart';
import '../../domain/todo.dart';
import '../bloc/todo_bloc.dart';
import '../bloc/todo_event.dart';
import '../bloc/todo_state.dart';
import '../widgets/todo_tile.dart';
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
        uuid: const Uuid(),
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
      appBar: AppBar(title: const Text('Todos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          if (state is TodosLoading || state is TodosInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TodosError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          final loaded = state as TodosLoaded;
          if (loaded.items.isEmpty) {
            return const EmptyState(
              title: 'No todos yet',
              subtitle: 'Tap + to add your first todo.',
              icon: Icons.check_circle_outline,
            );
          }
          return ListView.builder(
            itemCount: loaded.items.length,
            itemBuilder: (context, i) {
              final todo = loaded.items[i];
              return TodoTile(
                todo: todo,
                completion: loaded.completionsByTodoId[todo.id],
                onToggleComplete: () => context
                    .read<TodoBloc>()
                    .add(TodoCompletionToggled(todo.id)),
                onTap: () => _openForm(context, existing: todo),
                onDelete: () =>
                    context.read<TodoBloc>().add(TodoDeleted(todo.id)),
              );
            },
          );
        },
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
