import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

/// Historial de ventas del día — lista con totales y detalles.
class SalesHistoryScreen extends StatelessWidget {
  final List<CompletedSale> sales;

  const SalesHistoryScreen({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    final todaySales = sales.where((s) => _isToday(s.completedAt)).toList();
    final totalDay = todaySales.fold(
      Money.zero,
      (sum, s) => sum + s.finalAmount,
    );
    final totalItems = todaySales.fold(0, (sum, s) => sum + s.totalItems);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas del día'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Resumen del día
          _DaySummary(
            salesCount: todaySales.length,
            totalItems: totalItems,
            totalAmount: totalDay,
          ),
          const Divider(height: 1),
          // Lista de ventas
          Expanded(
            child: todaySales.isEmpty
                ? const Center(
                    child: Text(
                      'Todavía no hay ventas hoy.\n¡A vender!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: McColors.textSecondaryLight),
                    ),
                  )
                : ListView.builder(
                    itemCount: todaySales.length,
                    itemBuilder: (_, i) {
                      final sale = todaySales[todaySales.length - 1 - i];
                      return _SaleCard(
                        sale: sale,
                        index: todaySales.length - i,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _DaySummary extends StatelessWidget {
  final int salesCount;
  final int totalItems;
  final Money totalAmount;

  const _DaySummary({
    required this.salesCount,
    required this.totalItems,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(McSpacing.lg),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(label: 'Ventas', value: '$salesCount'),
          _StatColumn(label: 'Items', value: '$totalItems'),
          _StatColumn(
            label: 'Total',
            value: totalAmount.formatted,
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatColumn({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: McSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: highlight ? McColors.success : null,
              ),
        ),
      ],
    );
  }
}

class _SaleCard extends StatelessWidget {
  final CompletedSale sale;
  final int index;

  const _SaleCard({required this.sale, required this.index});

  @override
  Widget build(BuildContext context) {
    final time =
        '${sale.completedAt.hour.toString().padLeft(2, '0')}:${sale.completedAt.minute.toString().padLeft(2, '0')}';

    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
        child: Text('#$index'),
      ),
      title: Text(sale.finalAmount.formatted,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        '$time — ${sale.customerName} — ${sale.paymentMethodName}',
      ),
      trailing: Text(
        '${sale.totalItems} items',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      children: sale.items
          .map((item) => ListTile(
                dense: true,
                title: Text(item.productName),
                trailing: Text(
                  '${item.quantity} × ${item.unitPrice.formatted} = ${item.subtotal.formatted}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ))
          .toList(),
    );
  }
}

/// Venta completada — snapshot inmutable para el historial.
class CompletedSale {
  final String id;
  final List<PosSaleItem> items;
  final Money totalAmount;
  final Money discountAmount;
  final Money finalAmount;
  final Money amountPaid;
  final Money change;
  final String customerName;
  final String paymentMethodName;
  final int totalItems;
  final DateTime completedAt;

  CompletedSale({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.amountPaid,
    required this.change,
    required this.customerName,
    required this.paymentMethodName,
    required this.totalItems,
    required this.completedAt,
  });

  factory CompletedSale.fromPosSale(
    PosSale sale, {
    required String customerName,
    required String paymentMethodName,
  }) {
    return CompletedSale(
      id: sale.id,
      items: List.unmodifiable(sale.items),
      totalAmount: sale.totalAmount,
      discountAmount: sale.discountAmount,
      finalAmount: sale.finalAmount,
      amountPaid: sale.amountPaid,
      change: sale.change,
      customerName: customerName,
      paymentMethodName: paymentMethodName,
      totalItems: sale.totalItems,
      completedAt: DateTime.now(),
    );
  }
}
