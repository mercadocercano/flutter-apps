import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

/// Panel del carrito — muestra items, total y botón cobrar.
class CartPanel extends StatelessWidget {
  final PosSale sale;
  final ValueChanged<String> onRemoveItem;
  final void Function(String itemId, int quantity) onUpdateQuantity;
  final VoidCallback onComplete;
  final VoidCallback? onClear;
  final ScrollController? scrollController;

  const CartPanel({
    super.key,
    required this.sale,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onComplete,
    this.onClear,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Header ───
        Padding(
          padding: const EdgeInsets.fromLTRB(McSpacing.base, McSpacing.base, McSpacing.base, McSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Venta actual',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    '${sale.totalItems} ${sale.totalItems == 1 ? 'unidad' : 'unidades'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: McColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
              if (!sale.isEmpty && onClear != null)
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(foregroundColor: McColors.error),
                  child: const Text('Vaciar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),

        // ─── Items ───
        Expanded(
          child: sale.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: McSpacing.sm),
                      Text(
                        'Carrito vacío',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: McColors.textFg2,
                            ),
                      ),
                      const SizedBox(height: McSpacing.xs),
                      Text(
                        'Tocá un producto para empezar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: McColors.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: McSpacing.xs),
                  itemCount: sale.items.length,
                  itemBuilder: (_, i) => _CartItem(
                    item: sale.items[i],
                    onRemove: () => onRemoveItem(sale.items[i].id),
                    onQuantityChanged: (q) =>
                        onUpdateQuantity(sale.items[i].id, q),
                  ),
                ),
        ),

        // ─── Footer ───
        Container(
          padding: const EdgeInsets.all(McSpacing.base),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: _CartFooter(sale: sale, onComplete: onComplete),
        ),
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
        horizontal: McSpacing.base,
        vertical: McSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Nombre + subtotal ───
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF050C40),
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: McSpacing.sm),
              Text(
                item.subtotal.formatted,
                style: McTypography.mono(15, weight: FontWeight.w600, color: const Color(0xFF050C40)),
              ),
            ],
          ),
          const SizedBox(height: McSpacing.xs),

          // ─── Precio unitario + stepper ───
          Row(
            children: [
              Text(
                '${item.unitPrice.formatted} c/u',
                style: McTypography.mono(11, weight: FontWeight.w400, color: McColors.textFg2),
              ),
              const Spacer(),

              // Stepper
              Row(
                children: [
                  _StepperButton(
                    icon: Icons.remove,
                    onPressed: () => onQuantityChanged(item.quantity - 1),
                    variant: _StepperVariant.minus,
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: const Border.symmetric(
                        horizontal: BorderSide(color: Color(0xFFE2E8F0), width: 2),
                      ),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: McTypography.mono(16, weight: FontWeight.w600, color: const Color(0xFF050C40)),
                    ),
                  ),
                  _StepperButton(
                    icon: Icons.add,
                    onPressed: () => onQuantityChanged(item.quantity + 1),
                    variant: _StepperVariant.plus,
                  ),
                  const SizedBox(width: McSpacing.sm),
                  // Borrar
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFAAB7B8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _StepperVariant { minus, plus }

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final _StepperVariant variant;

  const _StepperButton({
    required this.icon,
    required this.onPressed,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final isMinus = variant == _StepperVariant.minus;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isMinus ? Colors.white : McColors.cobaltTint,
          border: Border.all(
            color: isMinus ? const Color(0xFFE2E8F0) : McColors.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.horizontal(
            left: isMinus ? const Radius.circular(8) : Radius.zero,
            right: isMinus ? Radius.zero : const Radius.circular(8),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isMinus ? McColors.textFg2 : McColors.primary,
        ),
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Total',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: McColors.textFg2,
                  ),
            ),
            Text(
              sale.finalAmount.formatted,
              style: McTypography.mono(32, color: const Color(0xFF050C40)),
            ),
          ],
        ),
        const SizedBox(height: McSpacing.base),
        McButton(
          label: 'Cobrar',
          icon: Icons.arrow_forward,
          size: McButtonSize.lg,
          expand: true,
          onPressed: sale.isEmpty ? null : onComplete,
        ),
      ],
    );
  }
}
