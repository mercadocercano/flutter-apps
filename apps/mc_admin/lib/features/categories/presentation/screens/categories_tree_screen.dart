import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_design_system/mc_design_system.dart';

import '../../domain/models/category_model.dart';
import '../bloc/categories_bloc.dart';
import '../../../../shared/widgets/admin_modal.dart';

class CategoriesTreeScreen extends StatefulWidget {
  const CategoriesTreeScreen({super.key});

  @override
  State<CategoriesTreeScreen> createState() => _CategoriesTreeScreenState();
}

class _CategoriesTreeScreenState extends State<CategoriesTreeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoriesBloc>().add(LoadCategoriesEvent());
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final confirmed = await showAdminConfirm(
      context: context,
      title: 'Eliminar categoría',
      message: '¿Eliminar "${category.name}"? Sus subcategorías también serán eliminadas.',
      confirmLabel: 'Eliminar',
      confirmColor: McColors.error,
    );
    if (confirmed && context.mounted) {
      context.read<CategoriesBloc>().add(DeleteCategoryEvent(category.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/categories/new'),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (context, state) {
          if (state is CategoriesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CategoriesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: McColors.error),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context
                        .read<CategoriesBloc>()
                        .add(LoadCategoriesEvent()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          if (state is CategoriesLoaded) {
            if (state.categories.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, size: 64, color: McColors.textSecondaryLight),
                    SizedBox(height: 16),
                    Text('No hay categorías', style: TextStyle(color: McColors.textSecondaryLight)),
                  ],
                ),
              );
            }
            final roots =
                state.categories.where((c) => c.parentId == null).toList();
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
              itemCount: roots.length,
              itemBuilder: (context, index) => _CategoryNode(
                category: roots[index],
                allCategories: state.categories,
                onDelete: _confirmDelete,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CategoryNode extends StatelessWidget {
  final Category category;
  final List<Category> allCategories;
  final Future<void> Function(BuildContext, Category) onDelete;

  const _CategoryNode({
    required this.category,
    required this.allCategories,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final children =
        allCategories.where((c) => c.parentId == category.id).toList();
    final indent = (category.level * 24.0).clamp(0.0, 96.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: ListTile(
            leading: Icon(
              children.isNotEmpty ? Icons.folder_outlined : Icons.label_outline,
              size: 20,
            ),
            title: Text(category.name),
            subtitle: Text(
              'Nivel ${category.level}${category.isActive ? "" : " · Inactiva"}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  tooltip: 'Agregar subcategoria',
                  onPressed: () =>
                      context.push('/categories/new?parentId=${category.id}'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Editar',
                  onPressed: () =>
                      context.push('/categories/${category.id}/edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: McColors.error),
                  tooltip: 'Eliminar',
                  onPressed: () => onDelete(context, category),
                ),
              ],
            ),
          ),
        ),
        if (children.isNotEmpty)
          ...children.map(
            (child) => _CategoryNode(
              category: child,
              allCategories: allCategories,
              onDelete: onDelete,
            ),
          ),
      ],
    );
  }
}
