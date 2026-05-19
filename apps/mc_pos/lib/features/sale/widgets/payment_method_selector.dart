import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

/// Selector de medio de pago — chips visuales.
class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod> onSelected;

  const PaymentMethodSelector({
    super.key,
    this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: McSpacing.sm,
      runSpacing: McSpacing.sm,
      children: _demoMethods.map((method) {
        final isSelected = selected?.id == method.id;
        return _PaymentChip(
          method: method,
          isSelected: isSelected,
          onTap: () => onSelected(method),
        );
      }).toList(),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentChip({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon => switch (method.code) {
        'cash' => Icons.payments_outlined,
        'debit_card' => Icons.credit_card,
        'credit_card' => Icons.credit_score,
        'qr' => Icons.qr_code_2,
        'transfer' => Icons.account_balance,
        'mercadopago' => Icons.phone_android,
        _ => Icons.payment,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? McColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(McSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: McSpacing.base,
            vertical: McSpacing.md,
          ),
          constraints: const BoxConstraints(
            minHeight: McSpacing.touchTargetMin,
            minWidth: 100,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? McColors.primary : McColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(McSpacing.radiusLg),
          ),
          child: Column(
            children: [
              Icon(
                _icon,
                size: 24,
                color: isSelected ? Colors.white : McColors.primary,
              ),
              const SizedBox(height: McSpacing.xs),
              Text(
                method.name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected ? Colors.white : null,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Medios de pago globales — UUIDs fijos seeded en payment_method_db.
/// Cuando payment-method-service esté en stack completo, reemplazar con carga dinámica.
final _demoMethods = [
  const PaymentMethod(
      id: '00000001-0000-0000-0000-000000000001', code: 'cash', name: 'Efectivo', isGlobal: true),
  const PaymentMethod(
      id: '00000001-0000-0000-0000-000000000002', code: 'debit_card', name: 'Débito', isGlobal: true),
  const PaymentMethod(
      id: '00000001-0000-0000-0000-000000000003', code: 'credit_card', name: 'Crédito', isGlobal: true),
  const PaymentMethod(
      id: '00000001-0000-0000-0000-000000000004', code: 'qr', name: 'QR', isGlobal: true),
  const PaymentMethod(
      id: '00000001-0000-0000-0000-000000000005', code: 'transfer', name: 'Transferencia', isGlobal: true),
  const PaymentMethod(
      id: '00000001-0000-0000-0000-000000000006', code: 'mercadopago', name: 'MercadoPago', isGlobal: true),
];
