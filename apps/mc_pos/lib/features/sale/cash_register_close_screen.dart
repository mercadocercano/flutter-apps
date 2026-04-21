import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import 'sales_history_screen.dart';

/// Cierre de caja / arqueo — resumen por medio de pago + diferencia.
class CashRegisterCloseScreen extends StatefulWidget {
  final List<CompletedSale> sales;
  final VoidCallback onClose;

  const CashRegisterCloseScreen({
    super.key,
    required this.sales,
    required this.onClose,
  });

  @override
  State<CashRegisterCloseScreen> createState() =>
      _CashRegisterCloseScreenState();
}

class _CashRegisterCloseScreenState extends State<CashRegisterCloseScreen> {
  final _cashCountController = TextEditingController();

  Map<String, Money> get _salesByMethod {
    final map = <String, Money>{};
    for (final sale in widget.sales) {
      map.update(
        sale.paymentMethodName,
        (existing) => existing + sale.finalAmount,
        ifAbsent: () => sale.finalAmount,
      );
    }
    return map;
  }

  Money get _totalSales =>
      widget.sales.fold(Money.zero, (sum, s) => sum + s.finalAmount);

  Money get _cashExpected => _salesByMethod['Efectivo'] ?? Money.zero;

  @override
  void dispose() {
    _cashCountController.dispose();
    super.dispose();
  }

  void _confirmClose() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar la caja?'),
        content: const Text(
          'Se va a registrar el cierre. Las ventas del día quedan guardadas.',
        ),
        actions: [
          McButton(
            label: 'Cancelar',
            variant: McButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          McButton(
            label: 'Cerrar caja',
            variant: McButtonVariant.destructive,
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onClose();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cashCounted = double.tryParse(_cashCountController.text) ?? 0;
    final difference = Money.ars(cashCounted) - _cashExpected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierre de caja'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(McSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen general
              McCard(
                child: Column(
                  children: [
                    _SummaryRow(
                      'Total del día',
                      _totalSales.formatted,
                      isBold: true,
                      isLarge: true,
                    ),
                    const Divider(),
                    _SummaryRow(
                      'Cantidad de ventas',
                      '${widget.sales.length}',
                    ),
                    _SummaryRow(
                      'Items vendidos',
                      '${widget.sales.fold(0, (sum, s) => sum + s.totalItems)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: McSpacing.lg),

              // Desglose por medio de pago
              Text('Desglose por medio de pago',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: McSpacing.sm),
              McCard(
                child: Column(
                  children: _salesByMethod.entries.map((entry) {
                    final count = widget.sales
                        .where((s) => s.paymentMethodName == entry.key)
                        .length;
                    return _SummaryRow(
                      '${entry.key} ($count ventas)',
                      entry.value.formatted,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: McSpacing.lg),

              // Arqueo de efectivo
              Text('Arqueo de efectivo',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: McSpacing.sm),
              McCard(
                child: Column(
                  children: [
                    _SummaryRow(
                      'Efectivo esperado',
                      _cashExpected.formatted,
                    ),
                    const SizedBox(height: McSpacing.md),
                    McTextField(
                      label: 'Efectivo contado en caja',
                      controller: _cashCountController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.calculate,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_cashCountController.text.isNotEmpty) ...[
                      const SizedBox(height: McSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(McSpacing.md),
                        decoration: BoxDecoration(
                          color: difference.cents == 0
                              ? McColors.success.withValues(alpha: 0.1)
                              : McColors.warning.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(McSpacing.radiusMd),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              difference.cents == 0
                                  ? 'Cuadra perfecto'
                                  : difference.isPositive
                                      ? 'Sobrante'
                                      : 'Faltante',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: difference.cents == 0
                                    ? McColors.success
                                    : McColors.warning,
                              ),
                            ),
                            Text(
                              difference.cents == 0
                                  ? '\$0,00'
                                  : difference.formatted,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: difference.cents == 0
                                        ? McColors.success
                                        : McColors.warning,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: McSpacing.xl),

              // Botón cerrar
              McButton(
                label: 'Cerrar caja',
                icon: Icons.lock,
                size: McButtonSize.lg,
                expand: true,
                variant: McButtonVariant.destructive,
                onPressed: widget.sales.isEmpty ? null : _confirmClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isLarge;

  const _SummaryRow(
    this.label,
    this.value, {
    this.isBold = false,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: McSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: (isLarge
                    ? Theme.of(context).textTheme.headlineSmall
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isLarge ? McColors.success : null,
            ),
          ),
        ],
      ),
    );
  }
}
