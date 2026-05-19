import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

/// Distribución completa de ventas por hora del día.
class HoursDetailScreen extends StatelessWidget {
  final List<PosSale> sales;

  const HoursDetailScreen({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(sales);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios pico'),
        backgroundColor: McColors.warning,
        foregroundColor: Colors.white,
      ),
      body: rows.isEmpty
          ? _buildEmpty()
          : _buildList(rows),
    );
  }

  Widget _buildEmpty() => const Center(
        child: Text(
          'Sin datos de horarios hoy',
          style: TextStyle(color: McColors.textSecondaryLight),
        ),
      );

  Widget _buildList(List<_HourRow> rows) {
    final maxCount = rows.fold(0, (m, r) => r.count > m ? r.count : m);
    return ListView.builder(
      padding: const EdgeInsets.all(McSpacing.base),
      itemCount: rows.length,
      itemBuilder: (_, i) => _HourTile(row: rows[i], maxCount: maxCount),
    );
  }

  List<_HourRow> _buildRows(List<PosSale> sales) {
    final map = <int, _HourRow>{};

    for (final sale in sales) {
      final h = sale.createdAt.hour;
      final prev = map[h] ?? _HourRow(hour: h, count: 0, revenue: Money.zero);
      map[h] = _HourRow(
        hour: h,
        count: prev.count + 1,
        revenue: prev.revenue + sale.finalAmount,
      );
    }

    if (map.isEmpty) return [];

    // Incluir horas adyacentes vacías para contexto visual
    final minH = map.keys.reduce((a, b) => a < b ? a : b);
    final maxH = map.keys.reduce((a, b) => a > b ? a : b);
    final start = (minH - 1).clamp(0, 23);
    final end = (maxH + 1).clamp(0, 23);

    return List.generate(end - start + 1, (i) {
      final h = start + i;
      return map[h] ?? _HourRow(hour: h, count: 0, revenue: Money.zero);
    });
  }
}

class _HourRow {
  final int hour;
  final int count;
  final Money revenue;
  const _HourRow({required this.hour, required this.count, required this.revenue});
}

class _HourTile extends StatelessWidget {
  final _HourRow row;
  final int maxCount;

  const _HourTile({required this.row, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final isPeak = maxCount > 0 && row.count == maxCount && row.count > 0;
    final fraction = maxCount > 0 ? row.count / maxCount : 0.0;
    final barColor = isPeak ? McColors.warning : McColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: McSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: McSpacing.md,
        vertical: McSpacing.sm,
      ),
      decoration: isPeak
          ? BoxDecoration(
              color: McColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(McSpacing.radiusMd),
              border: Border.all(color: McColors.warning.withValues(alpha: 0.3)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  '${row.hour.toString().padLeft(2, '0')}:00 - ${(row.hour + 1).clamp(0, 23).toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
                    color: isPeak ? McColors.warning : McColors.textSecondaryLight,
                  ),
                ),
              ),
              if (isPeak)
                const Padding(
                  padding: EdgeInsets.only(right: McSpacing.xs),
                  child: Icon(Icons.local_fire_department, size: 14, color: McColors.warning),
                ),
              Expanded(
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: McColors.borderLight,
                  color: barColor,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: McSpacing.sm),
              Text(
                '${row.count} ventas',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (row.count > 0) ...[
            const SizedBox(height: McSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 80),
              child: Text(
                row.revenue.formatted,
                style: const TextStyle(fontSize: 11, color: McColors.textSecondaryLight),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
