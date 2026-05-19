import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

/// Ranking detallado de productos por unidades vendidas.
class TopProductsDetailScreen extends StatelessWidget {
  final List<PosSale> sales;

  const TopProductsDetailScreen({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    final ranking = _buildRanking(sales);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top productos'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ranking.isEmpty
          ? _buildEmpty()
          : _buildList(ranking),
    );
  }

  Widget _buildEmpty() => const Center(
        child: Text(
          'Sin datos de productos hoy',
          style: TextStyle(color: McColors.textSecondaryLight),
        ),
      );

  Widget _buildList(List<_ProductRank> ranking) {
    final maxUnits = ranking.first.units;
    return ListView.separated(
      padding: const EdgeInsets.all(McSpacing.base),
      itemCount: ranking.length,
      separatorBuilder: (_, _) => const SizedBox(height: McSpacing.sm),
      itemBuilder: (_, i) => _ProductRow(rank: ranking[i], maxUnits: maxUnits),
    );
  }

  List<_ProductRank> _buildRanking(List<PosSale> sales) {
    final unitMap = <String, int>{};
    final revenueMap = <String, Money>{};

    for (final sale in sales) {
      for (final item in sale.items) {
        unitMap[item.productName] = (unitMap[item.productName] ?? 0) + item.quantity;
        revenueMap[item.productName] =
            (revenueMap[item.productName] ?? Money.zero) + item.subtotal;
      }
    }

    final sorted = unitMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.asMap().entries.map((e) => _ProductRank(
          rank: e.key + 1,
          name: e.value.key,
          units: e.value.value,
          revenue: revenueMap[e.value.key] ?? Money.zero,
        )).toList();
  }
}

class _ProductRank {
  final int rank;
  final String name;
  final int units;
  final Money revenue;
  const _ProductRank({
    required this.rank,
    required this.name,
    required this.units,
    required this.revenue,
  });
}

class _ProductRow extends StatelessWidget {
  final _ProductRank rank;
  final int maxUnits;

  const _ProductRow({required this.rank, required this.maxUnits});

  @override
  Widget build(BuildContext context) {
    final fraction = maxUnits > 0 ? rank.units / maxUnits : 0.0;

    return Container(
      padding: const EdgeInsets.all(McSpacing.md),
      decoration: BoxDecoration(
        color: McColors.surfaceLight,
        borderRadius: BorderRadius.circular(McSpacing.radiusMd),
        border: Border.all(color: McColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RankBadge(rank: rank.rank),
              const SizedBox(width: McSpacing.sm),
              Expanded(
                child: Text(
                  rank.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${rank.units} un.',
                style: const TextStyle(fontWeight: FontWeight.bold, color: McColors.primary),
              ),
            ],
          ),
          const SizedBox(height: McSpacing.xs),
          LinearProgressIndicator(
            value: fraction,
            backgroundColor: McColors.borderLight,
            color: McColors.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: McSpacing.xs),
          Text(
            rank.revenue.formatted,
            style: const TextStyle(fontSize: 12, color: McColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: McColors.primary.withValues(alpha: 0.1),
      child: Text(
        '$rank',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: McColors.primary),
      ),
    );
  }
}
