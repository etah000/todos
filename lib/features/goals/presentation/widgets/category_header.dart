import 'package:flutter/material.dart';

import '../../domain/category.dart';

class CategoryHeader extends StatelessWidget {
  const CategoryHeader({
    super.key,
    required this.category,
    required this.initiallyExpanded,
    required this.onEdit,
    required this.onDelete,
    this.children = const [],
  });

  final Category category;
  final bool initiallyExpanded;
  final List<Widget> children;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(category.title),
        subtitle: (category.description ?? '').isEmpty ? null : Text(category.description!),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit(category);
            if (v == 'delete') onDelete(category);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit Category')),
            PopupMenuItem(value: 'delete', child: Text('Delete Category')),
          ],
        ),
        children: children,
      ),
    );
  }
}
