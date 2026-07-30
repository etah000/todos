import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database_scope.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/category_repository.dart';
import '../../data/goal_activity_repository.dart';
import '../../data/goal_log_repository.dart';
import '../../domain/category.dart';
import '../../domain/goal_activity.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../widgets/category_header.dart';
import '../widgets/goal_tile.dart';
import 'category_form_page.dart';
import 'goal_detail_page.dart';
import 'goal_form_page.dart';

class GoalListPage extends StatelessWidget {
  const GoalListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return BlocProvider(
      create: (_) => GoalBloc(
        categoryRepo: CategoryRepository(db),
        activityRepo: GoalActivityRepository(db),
        logRepo: GoalLogRepository(db),
        uuid: const Uuid(),
      )..add(const GoalsSubscriptionRequested()),
      child: const _GoalListView(),
    );
  }
}

class _GoalListView extends StatelessWidget {
  const _GoalListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openFabSheet(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<GoalBloc, GoalState>(
        builder: (context, state) {
          if (state is GoalLoading || state is GoalInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GoalErrorState) {
            return _ErrorView(message: state.message, onRetry: () {
              context.read<GoalBloc>().add(const GoalsSubscriptionRequested());
            });
          }
          final loaded = state as GoalsLoaded;
          if (loaded.categories.isEmpty) {
            return const EmptyState(
              title: 'No categories yet',
              subtitle: 'Tap + to add a category or a goal.',
              icon: Icons.flag_outlined,
            );
          }
          return ListView(
            children: [
              for (final c in loaded.categories)
                CategoryHeader(
                  category: c,
                  initiallyExpanded: true,
                  onEdit: (cat) => _openCategoryForm(context, cat),
                  onDelete: (cat) => _confirmDeleteCategory(context, cat),
                  children: [
                    for (final a in loaded.activitiesByCategoryId[c.id] ?? const <GoalActivity>[])
                      GoalTile(activity: a, onTap: (act) => _openGoalDetail(context, act)),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Add goal'),
                      onTap: () => _openGoalForm(context, categoryId: c.id),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  void _openFabSheet(BuildContext context) {
    final bloc = context.read<GoalBloc>();
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text('New Category'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openCategoryForm(context, null);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('New Goal'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openGoalForm(context, categoryId: null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategoryForm(BuildContext context, Category? existing) {
    final bloc = context.read<GoalBloc>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc, child: CategoryFormPage(existing: existing),
      ),
    ));
  }

  void _openGoalForm(BuildContext context, {String? categoryId, GoalActivity? existing}) {
    final bloc = context.read<GoalBloc>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: GoalFormPage(categoryId: categoryId, existing: existing),
      ),
    ));
  }

  void _openGoalDetail(BuildContext context, GoalActivity activity) {
    final bloc = context.read<GoalBloc>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc, child: GoalDetailPage(activity: activity),
      ),
    ));
  }

  Future<void> _confirmDeleteCategory(BuildContext context, Category cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${cat.title}"?'),
        content: const Text(
          'This will permanently delete the category and every goal and log inside it.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<GoalBloc>().add(CategoryDeleted(cat.id));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Error: $message'),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}