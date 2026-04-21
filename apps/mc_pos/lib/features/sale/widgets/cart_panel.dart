import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

/// Panel del carrito — muestra items, total y botón cobrar.
class CartPanel extends StatelessWidget {
  final PosSale sale;
  final ValueChanged<String> onRemoveItem;
  final void Function(String itemId, int quantity) onUpdateQuantity;
  final VoidCallback onComplete;
  final ScrollController? scrollController;

  const CartPanel({
    super.key,
    required this.sale,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onComplete,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(McSpacing.md),
          child: Row(
            children: [
              Icon(Icons.shopping_cart, color: McColors.primary),
              const SizedBox(width: McSpacing.sm),
              Text(
                'Carrito (${sale.totalItems})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: sale.isEmpty
              ? const Center(
                  child: Text(
                    'Tocá un producto para agregarlo',
                    style: TextStyle(color: McColors.textSecondaryLight),
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: McSpacing.sm),
                  itemCount: sale.items.length,
                  itemBuilder: (_, i) => _CartItem(
                    item: sale.items[i],
                    onRemove: () => onRemoveItem(sale.items[i].id),
                    onQuantityChanged: (q) =>
                        onUpdateQuantity(sale.items[i].id, q),
                  ),
                ),
        ),
        const Divider(height: 1),
        _CartFooter(sale: sale, onComplete: onComplete),
      ],
    );
  }
}

class _CartItem extends StatelessWidget {
  final PosSaleItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const _CartItem({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: McSpacing.md,
        vertical: McSpacing.xs,
      ),
      child: Row(
        children: [
          // Cantidad con +/-
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: () => onQuantityChanged(item.quantity - 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: McSpacing.touchTargetMin,
              minHeight: McSpacing.touchTargetMin,
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: () => onQuantityChanged(item.quantity + 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: McSpacing.touchTargetMin,
              minHeight: McSpacing.touchTargetMin,
            ),
          ),
          const SizedBox(width: McSpacing.sm),
          // Nombre
          Expanded(
            child: Text(
              item.productName,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Subtotal
          Text(
            item.subtotal.formatted,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          // Borrar
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: McColors.error),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: McSpacing.touchTargetMin,
              minHeight: McSpacing.touchTargetMin,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartFooter extends StatelessWidget {
  final PosSale sale;
  final VoidCallback onComplete;

  const _CartFooter({required this.sale, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(McSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleLarge),
              Text(
                sale.finalAmount.formatted,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : McColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: McSpacing.md),
          McButton(
            label: 'Cobrar',
            icon: Icons.payment,
            size: McButtonSize.lg,
            expand: true,
            onPressed: sale.isEmpty ? null : onComplete,
          ),
        ],
      ),
    );
  }
}
