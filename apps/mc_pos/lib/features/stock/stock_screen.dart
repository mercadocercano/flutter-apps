import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

/// Pantalla de stock — ver inventario, ajustar cantidades, alertas de bajo stock.
/// Usa CatalogPort para listar variantes y StockPort para cantidades reales.
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _filter = 'todos'; // todos, bajo, sin
  List<_StockItem> _stockItems = [];
  bool _isLoading = true;
  static const _minStock = 5;

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    setState(() => _isLoading = true);
    try {
      final catalog = context.read<CatalogPort>();
      final stockPort = context.read<StockPort>();

      final products =
          await catalog.listProducts(status: ProductStatus.active);

      // Recolectar SKUs de todas las variantes activas
      final variants = <_VariantInfo>[];
      for (final product in products) {
        for (final variant in product.variants.where((v) => v.isActive)) {
          if (variant.sku != null) {
            variants.add(_VariantInfo(
              productName: product.name,
              variantName: variant.name,
              sku: variant.sku!.value,
              brandName: product.brandName ?? '',
            ));
          }
        }
      }

      // Consultar stock bulk por SKUs
      final skus = variants.map((v) => v.sku).toList();
      final stockMap =
          skus.isNotEmpty ? await stockPort.getStockForSkus(skus) : <String, int>{};

      final items = variants.map((v) {
        return _StockItem(
          name: '${v.productName} - ${v.variantName}',
          brand: v.brandName,
          sku: v.sku,
          stock: stockMap[v.sku] ?? 0,
          minStock: _minStock,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _stockItems = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_StockItem> get _filtered => switch (_filter) {
        'bajo' =>
          _stockItems.where((s) => s.stock > 0 && s.stock <= s.minStock).toList(),
        'sin' => _stockItems.where((s) => s.stock == 0).toList(),
        _ => _stockItems,
      };

  int get _lowStockCount =>
      _stockItems.where((s) => s.stock > 0 && s.stock <= s.minStock).length;
  int get _outOfStockCount =>
      _stockItems.where((s) => s.stock == 0).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(McSpacing.base),
            child: Row(
              children: [
                Expanded(
                  child: _StockSummaryCard(
                    label: 'Productos',
                    value: '${_stockItems.length}',
                    icon: Icons.inventory_2,
                    color: McColors.primary,
                    isSelected: _filter == 'todos',
                    onTap: () => setState(() => _filter = 'todos'),
                  ),
                ),
                const SizedBox(width: McSpacing.sm),
                Expanded(
                  child: _StockSummaryCard(
                    label: 'Bajo stock',
                    value: '$_lowStockCount',
                    icon: Icons.warning_amber,
                    color: McColors.warning,
                    isSelected: _filter == 'bajo',
                    onTap: () => setState(() => _filter = 'bajo'),
                  ),
                ),
                const SizedBox(width: McSpacing.sm),
                Expanded(
                  child: _StockSummaryCard(
                    label: 'Sin stock',
                    value: '$_outOfStockCount',
                    icon: Icons.error_outline,
                    color: McColors.error,
                    isSelected: _filter == 'sin',
                    onTap: () => setState(() => _filter = 'sin'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _filter == 'bajo'
                              ? 'No hay productos con bajo stock'
                              : _filter == 'sin'
                                  ? 'Todos los productos tienen stock'
                                  : 'No hay productos',
                          style: TextStyle(color: McColors.textSecondaryLight),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStock,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _StockTile(
                            item: _filtered[i],
                            onAdjust: () =>
                                _showAdjustStock(context, _filtered[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showAdjustStock(BuildContext context, _StockItem item) {
    final controller = TextEditingController();
    String type = 'RECEIPT';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(McSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: McSpacing.xs),
                  Text('Stock actual: ${item.stock}'),
                  const SizedBox(height: McSpacing.lg),
                  Text('Tipo de movimiento',
                      style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: McSpacing.sm),
                  Wrap(
                    spacing: McSpacing.sm,
                    children: [
                      _MovementChip(
                        label: 'Compra',
                        icon: Icons.add_shopping_cart,
                        isSelected: type == 'RECEIPT',
                        onTap: () => setSheetState(() => type = 'RECEIPT'),
                      ),
                      _MovementChip(
                        label: 'Ajuste',
                        icon: Icons.tune,
                        isSelected: type == 'ADJUSTMENT',
                        onTap: () =>
                            setSheetState(() => type = 'ADJUSTMENT'),
                      ),
                      _MovementChip(
                        label: 'Devolución',
                        icon: Icons.undo,
                        isSelected: type == 'RETURN',
                        onTap: () => setSheetState(() => type = 'RETURN'),
                      ),
                    ],
                  ),
                  const SizedBox(height: McSpacing.base),
                  McTextField(
                    label: 'Cantidad',
                    controller: controller,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.numbers,
                    autofocus: true,
                  ),
                  const SizedBox(height: McSpacing.lg),
                  McButton(
                    label: 'Registrar movimiento',
                    icon: Icons.check,
                    size: McButtonSize.lg,
                    expand: true,
                    onPressed: () async {
                      final qty =
                          double.tryParse(controller.text) ?? 0;
                      if (qty <= 0) return;

                      Navigator.of(ctx).pop();
                      try {
                        final stockPort = context.read<StockPort>();
                        await stockPort.adjustStock(
                          sku: item.sku,
                          quantity: qty,
                          entryType: type,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Stock de ${item.name} actualizado'),
                              backgroundColor: McColors.success,
                            ),
                          );
                          _loadStock();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: McColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StockSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StockSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return McCard(
      onTap: onTap,
      padding: const EdgeInsets.all(McSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: McSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : null,
                ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final _StockItem item;
  final VoidCallback onAdjust;

  const _StockTile({required this.item, required this.onAdjust});

  Color get _stockColor {
    if (item.stock == 0) return McColors.error;
    if (item.stock <= item.minStock) return McColors.warning;
    return McColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _stockColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(McSpacing.radiusSm),
        ),
        child: Center(
          child: Text(
            '${item.stock}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _stockColor,
            ),
          ),
        ),
      ),
      title:
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Row(
        children: [
          if (item.stock <= item.minStock && item.stock > 0)
            Text('Reponer',
                style: TextStyle(color: McColors.warning, fontSize: 12)),
          if (item.stock == 0)
            Text('Sin stock',
                style: TextStyle(color: McColors.error, fontSize: 12)),
        ],
      ),
      trailing: McButton(
        label: 'Ajustar',
        size: McButtonSize.sm,
        variant: McButtonVariant.outline,
        onPressed: onAdjust,
      ),
    );
  }
}

class _MovementChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MovementChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: McSpacing.xs),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _StockItem {
  final String name;
  final String brand;
  final String sku;
  final int stock;
  final int minStock;

  const _StockItem({
    required this.name,
    required this.brand,
    required this.sku,
    required this.stock,
    this.minStock = 5,
  });
}

class _VariantInfo {
  final String productName;
  final String variantName;
  final String sku;
  final String brandName;

  const _VariantInfo({
    required this.productName,
    required this.variantName,
    required this.sku,
    required this.brandName,
  });
}
