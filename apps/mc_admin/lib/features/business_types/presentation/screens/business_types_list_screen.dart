import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/business_types_repository.dart';
import '../../domain/models/business_type_model.dart';
import '../bloc/business_types_bloc.dart';
import 'business_type_templates_screen.dart';

class BusinessTypesListScreen extends StatefulWidget {
  const BusinessTypesListScreen({super.key});

  @override
  State<BusinessTypesListScreen> createState() =>
      _BusinessTypesListScreenState();
}

class _BusinessTypesListScreenState extends State<BusinessTypesListScreen> {
  bool _isReorderMode = false;
  bool _isSaving = false;
  List<BusinessType> _reordered = [];

  @override
  void initState() {
    super.initState();
    context.read<BusinessTypesBloc>().add(LoadBusinessTypesEvent());
  }

  void _enterReorder(List<BusinessType> types) {
    setState(() {
      _reordered = List.of(types);
      _isReorderMode = true;
    });
  }

  Future<void> _saveReorder() async {
    setState(() => _isSaving = true);
    try {
      final repo = context.read<BusinessTypesRepository>();
      await repo.reorder(_reordered);
      if (!mounted) return;
      setState(() {
        _isReorderMode = false;
        _isSaving = false;
      });
      context.read<BusinessTypesBloc>().add(LoadBusinessTypesEvent());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar orden: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelReorder() {
    setState(() {
      _isReorderMode = false;
      _reordered = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<BusinessTypesBloc, BusinessTypesState>(
        builder: (context, state) {
          if (state is BusinessTypesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BusinessTypesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context
                        .read<BusinessTypesBloc>()
                        .add(LoadBusinessTypesEvent()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          if (state is BusinessTypesLoaded) {
            if (state.businessTypes.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay tipos de comercio',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            return Column(
              children: [
                // ─── Header con botón reordenar ───
                _ReorderHeader(
                  isReorderMode: _isReorderMode,
                  isSaving: _isSaving,
                  onEnterReorder: () => _enterReorder(state.businessTypes),
                  onSave: _saveReorder,
                  onCancel: _cancelReorder,
                ),
                const Divider(height: 1),
                // ─── Lista ───
                Expanded(
                  child: _isReorderMode
                      ? _ReorderableList(
                          items: _reordered,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex--;
                              final item = _reordered.removeAt(oldIndex);
                              _reordered.insert(newIndex, item);
                            });
                          },
                        )
                      : _NormalList(businessTypes: state.businessTypes),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Header ───

class _ReorderHeader extends StatelessWidget {
  final bool isReorderMode;
  final bool isSaving;
  final VoidCallback onEnterReorder;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _ReorderHeader({
    required this.isReorderMode,
    required this.isSaving,
    required this.onEnterReorder,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (isReorderMode) ...[
            const Icon(Icons.drag_indicator_outlined,
                size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Arrastrá para reordenar',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: isSaving ? null : onCancel,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 16),
              label: const Text('Guardar orden'),
            ),
          ] else ...[
            const Expanded(child: SizedBox()),
            OutlinedButton.icon(
              onPressed: onEnterReorder,
              icon: const Icon(Icons.swap_vert, size: 16),
              label: const Text('Reordenar'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Lista normal (solo lectura) ───

class _NormalList extends StatelessWidget {
  final List<BusinessType> businessTypes;

  const _NormalList({required this.businessTypes});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: businessTypes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) =>
          _BusinessTypeItem(businessType: businessTypes[index]),
    );
  }
}

// ─── Lista reordenable ───

class _ReorderableList extends StatelessWidget {
  final List<BusinessType> items;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _ReorderableList({required this.items, required this.onReorder});

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      onReorder: onReorder,
      itemBuilder: (context, index) => _ReorderableItem(
        key: ValueKey(items[index].id),
        businessType: items[index],
        index: index,
      ),
    );
  }
}

class _ReorderableItem extends StatelessWidget {
  final BusinessType businessType;
  final int index;

  const _ReorderableItem({
    super.key,
    required this.businessType,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(businessType.color);
    return ListTile(
      key: key,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(
          _iconFromName(businessType.icon),
          color: color,
          size: 20,
        ),
      ),
      title: Text(businessType.name),
      subtitle: businessType.description != null
          ? Text(businessType.description!,
              maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: const Icon(Icons.drag_handle, color: Colors.grey),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blueGrey;
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.blueGrey;
    }
  }
}

// ─── Item normal expandible ───

class _BusinessTypeItem extends StatelessWidget {
  final BusinessType businessType;

  const _BusinessTypeItem({required this.businessType});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(businessType.color);
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(
          _iconFromName(businessType.icon),
          color: color,
          size: 20,
        ),
      ),
      title: Text(businessType.name),
      subtitle: businessType.description != null
          ? Text(businessType.description!,
              maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(
              businessType.isActive ? 'Activo' : 'Inactivo',
              style: TextStyle(
                color: businessType.isActive ? Colors.green : Colors.grey,
                fontSize: 11,
              ),
            ),
            visualDensity: VisualDensity.compact,
          ),
          const Icon(Icons.expand_more),
        ],
      ),
      children: [
        BusinessTypeTemplatesScreen(businessType: businessType),
      ],
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blueGrey;
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.blueGrey;
    }
  }
}

// ─── Icon helper ───

IconData _iconFromName(String? name) {
  switch (name) {
    case 'shopping-bag':
      return Icons.shopping_bag_outlined;
    case 'shopping_cart':
      return Icons.shopping_cart_outlined;
    case 'storefront':
      return Icons.storefront_outlined;
    case 'store':
      return Icons.store_outlined;
    case 'utensils':
    case 'restaurant':
      return Icons.restaurant_outlined;
    case 'briefcase':
      return Icons.work_outline;
    case 'truck':
      return Icons.local_shipping_outlined;
    case 'factory':
      return Icons.factory_outlined;
    case 'heart':
      return Icons.favorite_border;
    case 'medical_services':
      return Icons.medical_services_outlined;
    case 'graduation-cap':
      return Icons.school_outlined;
    case 'laptop':
      return Icons.laptop_outlined;
    case 'hardware':
      return Icons.hardware_outlined;
    case 'bakery_dining':
      return Icons.bakery_dining_outlined;
    case 'sparkles':
      return Icons.auto_awesome_outlined;
    case 'waves':
      return Icons.waves;
    case 'eco':
      return Icons.eco_outlined;
    case 'zap':
      return Icons.bolt_outlined;
    case 'wine':
      return Icons.wine_bar_outlined;
    case 'content_cut':
      return Icons.content_cut;
    case 'shopping_basket':
      return Icons.shopping_basket_outlined;
    case 'set_meal':
      return Icons.set_meal_outlined;
    case 'toys':
      return Icons.toys_outlined;
    case 'menu_book':
      return Icons.menu_book_outlined;
    case 'checkroom':
      return Icons.checkroom_outlined;
    case 'pets':
      return Icons.pets_outlined;
    case 'electrical_services':
      return Icons.electrical_services_outlined;
    default:
      return Icons.storefront_outlined;
  }
}
