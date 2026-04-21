import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

/// Pantalla de catálogo — ver, buscar y editar productos del comercio.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final catalog = context.read<CatalogPort>();
      final products = await catalog.listProducts(
        search: _query.isEmpty ? null : _query,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _categories {
    final cats = <String>{};
    for (final p in _products) {
      if (p.categoryName != null) cats.add(p.categoryName!);
    }
    return cats.toList()..sort();
  }

  List<Product> get _filtered {
    if (_selectedCategory == null) return _products;
    return _products
        .where((p) => p.categoryName == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Productos'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(McSpacing.md),
            child: McTextField(
              hint: 'Buscar por nombre, marca o código...',
              controller: _searchController,
              prefixIcon: Icons.search,
              onChanged: (v) {
                _query = v.toLowerCase();
                _loadProducts();
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: McSpacing.md),
              children: [
                _CategoryChip(
                  label: 'Todos',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ..._categories.map((cat) => _CategoryChip(
                      label: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    )),
              ],
            ),
          ),
          const SizedBox(height: McSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: McSpacing.base),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} productos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: McColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: McSpacing.sm),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProducts,
                child: ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) =>
                      _ProductTile(product: _filtered[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: McSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: McColors.primary.withValues(alpha: 0.15),
        checkmarkColor: McColors.primary,
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final activeVariants = product.variants.where((v) => v.isActive).toList();
    final defaultVariant =
        activeVariants.where((v) => v.isDefault).firstOrNull ??
            activeVariants.firstOrNull;

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: McColors.mutedLight,
          borderRadius: BorderRadius.circular(McSpacing.radiusSm),
        ),
        child: const Icon(Icons.inventory_2, color: McColors.textSecondaryLight),
      ),
      title: Text(product.name,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Row(
        children: [
          if (product.brandName != null) ...[
            Text(product.brandName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(width: McSpacing.sm),
          ],
          Text('${activeVariants.length} presentaciones',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      trailing: defaultVariant != null
          ? Text(
              defaultVariant.price.formatted,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            )
          : null,
    );
  }
}
