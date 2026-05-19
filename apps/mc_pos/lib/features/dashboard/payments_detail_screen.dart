import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

/// Detalle de métodos de pago con toggle Día / Mes.
class PaymentsDetailScreen extends StatefulWidget {
  final List<PosSale> sales;
  final List<PaymentMethod> paymentMethods;

  const PaymentsDetailScreen({
    super.key,
    required this.sales,
    required this.paymentMethods,
  });

  @override
  State<PaymentsDetailScreen> createState() => _PaymentsDetailScreenState();
}

class _PaymentsDetailScreenState extends State<PaymentsDetailScreen> {
  bool _isMonthView = false;
  List<PosSale> _sales = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _sales = widget.sales;
  }

  Future<void> _switchToMonth() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month);
      final salePort = context.read<SalePort>();
      final monthly = await salePort.listSales(from: startOfMonth, pageSize: 500);
      if (mounted) setState(() { _sales = monthly; _isMonthView = true; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchToDay() {
    setState(() { _sales = widget.sales; _isMonthView = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métodos de pago'),
        backgroundColor: McColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _ToggleBar(isMonth: _isMonthView, onDay: _switchToDay, onMonth: _switchToMonth),
          if (_loading) const LinearProgressIndicator(color: McColors.secondary),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final breakdown = _buildBreakdown(_sales, widget.paymentMethods);
    final total = breakdown.fold(Money.zero, (s, e) => s + e.amount);

    if (breakdown.isEmpty) {
      return const Center(
        child: Text('Sin datos', style: TextStyle(color: McColors.textSecondaryLight)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(McSpacing.base),
      children: breakdown
          .map((e) => _PaymentRow(entry: e, total: total))
          .toList(),
    );
  }

  List<_PaymentBreakdown> _buildBreakdown(
    List<PosSale> sales,
    List<PaymentMethod> methods,
  ) {
    final methodMap = {for (final m in methods) m.id: m.name};
    final amountMap = <String, Money>{};

    for (final sale in sales) {
      final key = methodMap[sale.paymentMethodId] ?? 'Sin especificar';
      amountMap[key] = (amountMap[key] ?? Money.zero) + sale.finalAmount;
    }

    return amountMap.entries
        .map((e) => _PaymentBreakdown(name: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.cents.compareTo(a.amount.cents));
  }
}

class _PaymentBreakdown {
  final String name;
  final Money amount;
  const _PaymentBreakdown({required this.name, required this.amount});
}

class _ToggleBar extends StatelessWidget {
  final bool isMonth;
  final VoidCallback onDay;
  final VoidCallback onMonth;

  const _ToggleBar({required this.isMonth, required this.onDay, required this.onMonth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(McSpacing.md),
      child: Row(
        children: [
          _ToggleButton(label: 'Día', active: !isMonth, onTap: onDay),
          const SizedBox(width: McSpacing.sm),
          _ToggleButton(label: 'Mes', active: isMonth, onTap: onMonth),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: McSpacing.md, vertical: McSpacing.sm),
        decoration: BoxDecoration(
          color: active ? McColors.secondary : McColors.mutedLight,
          borderRadius: BorderRadius.circular(McSpacing.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : McColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final _PaymentBreakdown entry;
  final Money total;

  const _PaymentRow({required this.entry, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total.cents > 0 ? entry.amount.cents / total.cents : 0.0;
    final pct = (fraction * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: McSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w500))),
              Text(entry.amount.formatted, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: McSpacing.sm),
              Text('$pct%', style: const TextStyle(color: McColors.textSecondaryLight, fontSize: 12)),
            ],
          ),
          const SizedBox(height: McSpacing.xs),
          LinearProgressIndicator(
            value: fraction,
            backgroundColor: McColors.borderLight,
            color: McColors.secondary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
