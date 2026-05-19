import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import '../settings/settings_screen.dart';
import 'sales_detail_screen.dart';
import 'top_products_detail_screen.dart';
import 'payments_detail_screen.dart';
import 'hours_detail_screen.dart';
import '../../widgets/pos/pos_top_bar.dart';
import '../../widgets/pos/product_card_pos.dart' show fmtAR;

/// Dashboard principal del POS — 4 mini-cards con KPIs del día.
class DashboardScreen extends StatefulWidget {
  final int refreshTrigger;

  const DashboardScreen({super.key, this.refreshTrigger = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<PosSale> _sales = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DashboardScreen old) {
    super.didUpdateWidget(old);
    if (widget.refreshTrigger != old.refreshTrigger) _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final salePort = context.read<SalePort>();
      final pmPort = context.read<PaymentMethodPort>();
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final results = await Future.wait([
        salePort.listSales(from: startOfDay, to: now, pageSize: 200),
        pmPort.listPaymentMethods().catchError((_) => <PaymentMethod>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _sales = results[0] as List<PosSale>;
        _paymentMethods = results[1] as List<PaymentMethod>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'No pudimos cargar el resumen. Verificá tu conexión.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: McColors.backgroundLight,
      body: Column(
        children: [
          PosTopBar(
            title: 'Resumen',
            subtitle: 'Hoy',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  color: McColors.textFg2,
                  tooltip: 'Actualizar',
                  onPressed: _isLoading ? null : _load,
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  color: McColors.textFg2,
                  tooltip: 'Configuración',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError();
    return _buildGrid();
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(McSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: McColors.error)),
            const SizedBox(height: McSpacing.md),
            McButton(label: 'Reintentar', onPressed: _load),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final revenue = _sales.fold(Money.zero, (s, v) => s + v.finalAmount);

    return ListView(
      padding: const EdgeInsets.all(McSpacing.base),
      children: [
        // Hero card con gradiente
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A21C0), Color(0xFF06178A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(McSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VENDISTE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fmtAR(revenue.amount),
                style: McTypography.mono(38, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'en ${_sales.length} venta${_sales.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: McSpacing.md),
        _buildRow(
          _buildSalesCard(),
          _buildTopProductsCard(),
        ),
        const SizedBox(height: McSpacing.sm),
        _buildRow(
          _buildPaymentsCard(),
          _buildHoursCard(),
        ),
      ],
    );
  }

  Widget _buildRow(Widget left, Widget right) => Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: McSpacing.sm),
          Expanded(child: right),
        ],
      );

  Widget _buildSalesCard() {
    final revenue = _sales.fold(Money.zero, (s, v) => s + v.finalAmount);
    final avg = _sales.isEmpty
        ? Money.zero
        : Money.ars(revenue.amount / _sales.length);

    return _MiniCard(
      title: 'Ventas del día',
      icon: Icons.attach_money,
      color: McColors.success,
      onTap: () => _push(SalesDetailScreen(sales: _sales)),
      children: [
        _MetricText(revenue.formatted, bold: true),
        _MetricText('${_sales.length} transacciones'),
        _MetricText('Promedio: ${avg.formatted}'),
      ],
    );
  }

  Widget _buildTopProductsCard() {
    final top = _topProducts();
    return _MiniCard(
      title: 'Top productos',
      icon: Icons.inventory_2_outlined,
      color: McColors.primary,
      onTap: () => _push(TopProductsDetailScreen(sales: _sales)),
      children: top.isEmpty
          ? [const _MetricText('Sin datos hoy')]
          : top.map((p) => _MetricText('${p.name} · ${p.units} un')).toList(),
    );
  }

  Widget _buildPaymentsCard() {
    final methodMap = {for (final m in _paymentMethods) m.id: m.name};
    final breakdown = _paymentBreakdown(methodMap);

    return _MiniCard(
      title: 'Métodos de pago',
      icon: Icons.payments_outlined,
      color: McColors.secondary,
      onTap: () => _push(PaymentsDetailScreen(sales: _sales, paymentMethods: _paymentMethods)),
      children: breakdown.isEmpty
          ? [const _MetricText('Sin ventas hoy')]
          : breakdown.take(3).map((e) => _MetricText('${e.name}: ${e.amount.formatted}')).toList(),
    );
  }

  Widget _buildHoursCard() {
    final peakInfo = _peakHourInfo();

    return _MiniCard(
      title: 'Horarios pico',
      icon: Icons.schedule_outlined,
      color: McColors.warning,
      onTap: () => _push(HoursDetailScreen(sales: _sales)),
      children: [
        _MetricText(peakInfo.peak),
        _MetricText(peakInfo.opening),
        _MetricText(peakInfo.closing),
      ],
    );
  }

  List<_NamedUnits> _topProducts() {
    final map = <String, int>{};
    for (final sale in _sales) {
      for (final item in sale.items) {
        map[item.productName] = (map[item.productName] ?? 0) + item.quantity;
      }
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => _NamedUnits(name: e.key, units: e.value)).toList();
  }

  List<_NamedMoney> _paymentBreakdown(Map<String, String> methodMap) {
    final amountMap = <String, Money>{};
    for (final sale in _sales) {
      final name = methodMap[sale.paymentMethodId] ?? 'Otro';
      amountMap[name] = (amountMap[name] ?? Money.zero) + sale.finalAmount;
    }
    return amountMap.entries
        .map((e) => _NamedMoney(name: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.cents.compareTo(a.amount.cents));
  }

  _PeakInfo _peakHourInfo() {
    if (_sales.isEmpty) {
      return const _PeakInfo(peak: 'Sin datos', opening: 'Apertura: —', closing: 'Cierre: —');
    }

    final hourCount = <int, int>{};
    for (final s in _sales) {
      final h = s.createdAt.hour;
      hourCount[h] = (hourCount[h] ?? 0) + 1;
    }

    final peakEntry = hourCount.entries.reduce((a, b) => a.value > b.value ? a : b);
    final sorted = _sales.map((s) => s.createdAt).toList()..sort();

    return _PeakInfo(
      peak: 'Pico: ${peakEntry.key}-${peakEntry.key + 1}hs (${peakEntry.value} ventas)',
      opening: 'Apertura: ${sorted.first.hour}hs',
      closing: 'Cierre: ${sorted.last.hour}hs',
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

// ─── Componente _MiniCard ───

class _MiniCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  final VoidCallback onTap;

  const _MiniCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        padding: const EdgeInsets.all(McSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(McSpacing.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardHeader(icon: icon, title: title, color: color),
            const SizedBox(height: McSpacing.sm),
            ...children,
            const SizedBox(height: McSpacing.sm),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Ver detalle →',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _CardHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: McSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MetricText extends StatelessWidget {
  final String text;
  final bool bold;

  const _MetricText(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: McSpacing.xs),
      child: Text(
        text,
        style: TextStyle(
          fontSize: bold ? 16 : 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: bold ? McColors.foregroundLight : McColors.textSecondaryLight,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Value objects locales ───

class _NamedUnits {
  final String name;
  final int units;
  const _NamedUnits({required this.name, required this.units});
}

class _NamedMoney {
  final String name;
  final Money amount;
  const _NamedMoney({required this.name, required this.amount});
}

class _PeakInfo {
  final String peak;
  final String opening;
  final String closing;
  const _PeakInfo({required this.peak, required this.opening, required this.closing});
}
