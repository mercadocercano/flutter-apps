import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

/// Detalle completo de ventas — KPIs + distribución horaria.
class SalesDetailScreen extends StatelessWidget {
  final List<PosSale> sales;

  const SalesDetailScreen({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas del día'),
        backgroundColor: McColors.success,
        foregroundColor: Colors.white,
      ),
      body: sales.isEmpty
          ? _buildEmpty()
          : ListView(
              padding: const EdgeInsets.all(McSpacing.base),
              children: [
                _KpiSection(sales: sales),
                const SizedBox(height: McSpacing.lg),
                _HourlySection(sales: sales),
              ],
            ),
    );
  }

  Widget _buildEmpty() => const Center(
        child: Text(
          'Sin ventas registradas hoy',
          style: TextStyle(color: McColors.textSecondaryLight),
        ),
      );
}

class _KpiSection extends StatelessWidget {
  final List<PosSale> sales;

  const _KpiSection({required this.sales});

  @override
  Widget build(BuildContext context) {
    final revenue = sales.fold(Money.zero, (s, v) => s + v.finalAmount);
    final units = sales.fold(0, (s, v) => s + v.totalItems);
    final avg = sales.isEmpty
        ? Money.zero
        : Money.ars(revenue.amount / sales.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('KPIs', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: McSpacing.sm),
        Wrap(
          spacing: McSpacing.sm,
          runSpacing: McSpacing.sm,
          children: [
            _KpiChip(label: 'Total', value: revenue.formatted, color: McColors.success),
            _KpiChip(label: 'Ventas', value: '${sales.length}', color: McColors.primary),
            _KpiChip(label: 'Ticket promedio', value: avg.formatted, color: McColors.secondary),
            _KpiChip(label: 'Unidades', value: '$units', color: McColors.warning),
          ],
        ),
      ],
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: McSpacing.md, vertical: McSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(McSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 11, color: McColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _HourlySection extends StatelessWidget {
  final List<PosSale> sales;

  const _HourlySection({required this.sales});

  @override
  Widget build(BuildContext context) {
    final hourMap = _buildHourMap(sales);
    final maxCount = hourMap.values.fold(0, (m, e) => e.count > m ? e.count : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Distribución por hora', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: McSpacing.sm),
        ...hourMap.entries.map((e) => _HourRow(entry: e.value, max: maxCount)),
      ],
    );
  }

  Map<int, _HourEntry> _buildHourMap(List<PosSale> sales) {
    final map = <int, _HourEntry>{};
    for (final sale in sales) {
      final h = sale.createdAt.hour;
      final prev = map[h] ?? _HourEntry(hour: h, count: 0, revenue: Money.zero);
      map[h] = _HourEntry(
        hour: h,
        count: prev.count + 1,
        revenue: prev.revenue + sale.finalAmount,
      );
    }
    final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return {for (final e in sorted) e.key: e.value};
  }
}

class _HourEntry {
  final int hour;
  final int count;
  final Money revenue;
  const _HourEntry({required this.hour, required this.count, required this.revenue});
}

class _HourRow extends StatelessWidget {
  final _HourEntry entry;
  final int max;

  const _HourRow({required this.entry, required this.max});

  @override
  Widget build(BuildContext context) {
    final fraction = max > 0 ? entry.count / max : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: McSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '${entry.hour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(fontSize: 12, color: McColors.textSecondaryLight),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: McColors.borderLight,
              color: McColors.success,
              minHeight: 10,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: McSpacing.sm),
          Text(
            '${entry.count} (${entry.revenue.formatted})',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
