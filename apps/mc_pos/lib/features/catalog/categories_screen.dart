import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import '../../widgets/pos/pos_modal.dart';

/// Pantalla de gestión de categorías con árbol padre/hijo.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _all = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final port = context.read<CategoryPort>();
      final items = await port.listCategories(pageSize: 200);
      if (mounted) setState(() {
        _all = items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'No pudimos cargar las categorías. Verificá tu conexión.';
        _isLoading = false;
      });
    }
  }

  List<Category> get _roots => _all.where((c) => c.isRoot).toList();

  List<Category> _childrenOf(String parentId) =>
      _all.where((c) => c.parentId == parentId).toList();

  Future<void> _showForm({Category? editing, Category? parent}) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final descCtrl = TextEditingController(text: editing?.description ?? '');

    String? title;
    if (editing != null) {
      title = 'Editar "${editing.name}"';
    } else if (parent != null) {
      title = 'Subcategoría de "${parent.name}"';
    } else {
      title = 'Nueva categoría';
    }

    final confirmed = await showPosDialog<bool>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(McSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: McColors.foregroundLight,
              ),
            ),
            const SizedBox(height: McSpacing.md),
            McTextField(controller: nameCtrl, hint: 'Nombre *', autofocus: true),
            const SizedBox(height: McSpacing.sm),
            McTextField(controller: descCtrl, hint: 'Descripción (opcional)'),
            const SizedBox(height: McSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                McButton(
                  label: 'Cancelar',
                  variant: McButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: McSpacing.sm),
                McButton(
                  label: 'Guardar',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    try {
      final port = context.read<CategoryPort>();
      if (editing == null) {
        await port.createCategory(
          name: name,
          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
          parentId: parent?.id,
        );
      } else {
        await port.updateCategory(
          categoryId: editing.id,
          name: name,
          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
          parentId: editing.parentId,
          active: editing.active,
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('No pudimos guardar la categoría. Intentá de nuevo.'), backgroundColor: McColors.error),
        );
      }
    }
  }

  Future<void> _confirmDeactivate(Category cat) async {
    final hasChildren = _childrenOf(cat.id).isNotEmpty;
    final confirmed = await showPosConfirm(
      context: context,
      title: 'Desactivar categoría',
      message: hasChildren
          ? '¿Desactivar "${cat.name}" y sus subcategorías?'
          : '¿Desactivar "${cat.name}"?',
      confirmLabel: 'Desactivar',
      confirmColor: McColors.error,
    );
    if (confirmed != true || !mounted) return;
    try {
      final port = context.read<CategoryPort>();
      if (hasChildren) {
        for (final child in _childrenOf(cat.id)) {
          await port.deleteCategory(child.id);
        }
      }
      await port.deleteCategory(cat.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('No pudimos desactivar la categoría. Intentá de nuevo.'), backgroundColor: McColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: McColors.primary,
        tooltip: 'Nueva categoría raíz',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(McSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: McColors.error),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: McSpacing.md),
            McButton(label: 'Reintentar', onPressed: _load),
          ],
        ),
      );
    }
    if (_all.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(McSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 64, color: McColors.textSecondaryLight),
            const SizedBox(height: McSpacing.md),
            Text('Sin categorías', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: McSpacing.sm),
            McButton(label: 'Crear primera categoría', onPressed: () => _showForm()),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _roots.length,
        itemBuilder: (_, i) => _CategoryNode(
          category: _roots[i],
          children: _childrenOf(_roots[i].id),
          onAddChild: (parent) => _showForm(parent: parent),
          onEdit: (cat) => _showForm(editing: cat),
          onDeactivate: _confirmDeactivate,
        ),
      ),
    );
  }
}

// ─── Nodo del árbol ───

class _CategoryNode extends StatefulWidget {
  final Category category;
  final List<Category> children;
  final void Function(Category parent) onAddChild;
  final void Function(Category cat) onEdit;
  final void Function(Category cat) onDeactivate;

  const _CategoryNode({
    required this.category,
    required this.children,
    required this.onAddChild,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  State<_CategoryNode> createState() => _CategoryNodeState();
}

class _CategoryNodeState extends State<_CategoryNode> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final hasChildren = widget.children.isNotEmpty;
    final textStyle = TextStyle(
      color: cat.active ? null : McColors.textSecondaryLight,
      decoration: cat.active ? null : TextDecoration.lineThrough,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Fila de categoría raíz ───
        ListTile(
          leading: hasChildren
              ? IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: McColors.primary,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                )
              : Icon(
                  Icons.label_outline,
                  color: cat.active ? McColors.primary : McColors.textSecondaryLight,
                ),
          title: Text(cat.name, style: textStyle.copyWith(fontWeight: FontWeight.w600)),
          subtitle: cat.description != null ? Text(cat.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
          trailing: _ActionMenu(
            onAddChild: () => widget.onAddChild(cat),
            onEdit: () => widget.onEdit(cat),
            onDeactivate: () => widget.onDeactivate(cat),
            isActive: cat.active,
          ),
        ),

        // ─── Subcategorías ───
        if (hasChildren && _expanded)
          Padding(
            padding: const EdgeInsets.only(left: McSpacing.xl),
            child: Column(
              children: [
                const Divider(height: 1, indent: McSpacing.sm),
                ...widget.children.map(
                  (child) => ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.subdirectory_arrow_right,
                      size: 18,
                      color: child.active ? McColors.textSecondaryLight : McColors.textSecondaryLight,
                    ),
                    title: Text(
                      child.name,
                      style: TextStyle(
                        color: child.active ? null : McColors.textSecondaryLight,
                        decoration: child.active ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: child.description != null
                        ? Text(child.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: _ActionMenu(
                      onAddChild: null,
                      onEdit: () => widget.onEdit(child),
                      onDeactivate: () => widget.onDeactivate(child),
                      isActive: child.active,
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),

        const Divider(height: 1),
      ],
    );
  }
}

// ─── Menú de acciones (3 puntos) ───

class _ActionMenu extends StatelessWidget {
  final VoidCallback? onAddChild;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final bool isActive;

  const _ActionMenu({
    required this.onAddChild,
    required this.onEdit,
    required this.onDeactivate,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Action>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (action) {
        switch (action) {
          case _Action.addChild:
            onAddChild?.call();
          case _Action.edit:
            onEdit();
          case _Action.deactivate:
            onDeactivate();
        }
      },
      itemBuilder: (_) => [
        if (onAddChild != null)
          const PopupMenuItem(
            value: _Action.addChild,
            child: ListTile(
              dense: true,
              leading: Icon(Icons.add),
              title: Text('Agregar subcategoría'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem(
          value: _Action.edit,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _Action.deactivate,
          child: ListTile(
            dense: true,
            leading: Icon(
              Icons.block_outlined,
              color: isActive ? McColors.error : McColors.textSecondaryLight,
            ),
            title: Text(
              isActive ? 'Desactivar' : 'Ya inactiva',
              style: TextStyle(
                color: isActive ? McColors.error : McColors.textSecondaryLight,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

enum _Action { addChild, edit, deactivate }
