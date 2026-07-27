import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import '../../widgets/pos/pos_top_bar.dart';
import '../../widgets/pos/product_card_pos.dart' show fmtAR;
import 'receipt/receipt_detail_screen.dart';

/// Historial de ventas — carga del backend + muestra ventas locales de la sesión.
class SalesHistoryScreen extends StatefulWidget {
  final List<CompletedSale> localSales;

  const SalesHistoryScreen({super.key, required this.localSales});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<PosSale> _remoteSales = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final salePort = context.read<SalePort>();
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final sales = await salePort.listSales(
        from: todayStart,
        pageSize: 100,
      );
      if (mounted) setState(() { _remoteSales = sales; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'No pudimos cargar las ventas. Verificá tu conexión.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _remoteSales.length;
    return Scaffold(
      backgroundColor: McColors.backgroundLight,
      body: Column(
        children: [
          PosTopBar(
            title: 'Historial',
            subtitle: '$count venta${count == 1 ? '' : 's'} hoy',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: McColors.textFg2),
              onPressed: () => Navigator.of(context).pop(),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh, color: McColors.textFg2),
              onPressed: _load,
              tooltip: 'Actualizar',
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error al cargar ventas', style: TextStyle(color: McColors.error)),
            const SizedBox(height: McSpacing.md),
            McButton(label: 'Reintentar', onPressed: _load),
          ],
        ),
      );
    }

    // Combinar ventas remotas y locales (sin duplicados por ID)
    final remoteIds = _remoteSales.map((s) => s.id).toSet();
    final localOnly = widget.localSales.where((s) => !remoteIds.contains(s.id)).toList();

    final totalAmount = _remoteSales.fold(
      Money.zero,
      (sum, s) => sum + s.finalAmount,
    );

    return Column(
      children: [
        _DaySummary(
          salesCount: _remoteSales.length + localOnly.length,
          totalAmount: totalAmount,
        ),
        const Divider(height: 1),
        Expanded(
          child: (_remoteSales.isEmpty && localOnly.isEmpty)
              ? const Center(
                  child: Text(
                    'Todavía no hay ventas hoy.\n¡A vender!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: McColors.textSecondaryLight),
                  ),
                )
              : ListView(
                  children: [
                    // Ventas del backend
                    ..._remoteSales.reversed.toList().asMap().entries.map((e) =>
                        _RemoteSaleCard(
                          sale: e.value,
                          index: _remoteSales.length - e.key,
                        )),
                    // Ventas locales no guardadas aún
                    ...localOnly.reversed.toList().asMap().entries.map((e) =>
                        _LocalSaleCard(sale: e.value)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DaySummary extends StatelessWidget {
  final int salesCount;
  final Money totalAmount;

  const _DaySummary({required this.salesCount, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(McSpacing.lg),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(label: 'Ventas', value: '$salesCount'),
          _StatColumn(label: 'Total', value: totalAmount.formatted, highlight: true),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatColumn({required this.label, required this.value, this.highlight = false});

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

class _RemoteSaleCard extends StatefulWidget {
  final PosSale sale;
  final int index;

  const _RemoteSaleCard({required this.sale, required this.index});

  @override
  State<_RemoteSaleCard> createState() => _RemoteSaleCardState();
}

class _RemoteSaleCardState extends State<_RemoteSaleCard> {
  bool _expanded = false;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final time = _formatTime(sale.createdAt);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: McSpacing.base,
            vertical: McSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _expanded ? McColors.backgroundLight : Colors.white,
            border: Border.all(color: McColors.borderLight),
            borderRadius: BorderRadius.circular(McSpacing.radiusLg),
          ),
          child: Column(
            children: [
              // Cabecera
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: McSpacing.md,
                  vertical: McSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: McColors.cobaltTint,
                        borderRadius:
                            BorderRadius.circular(McSpacing.radiusSm),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#${widget.index}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: McColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$time · ${sale.totalItems} producto${sale.totalItems == 1 ? '' : 's'}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${sale.totalItems} items',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: McColors.textFg2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      fmtAR(sale.finalAmount.amount),
                      style: McTypography.mono(14),
                    ),
                    const SizedBox(width: McSpacing.xs),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: McColors.textFg2,
                      ),
                    ),
                  ],
                ),
              ),

              // Detalle expandible
              if (_expanded)
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: McColors.mutedLight)),
                  ),
                  child: Column(
                    children: [
                      ...sale.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: McSpacing.md,
                              vertical: McSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '${item.quantity} × ${item.unitPrice.formatted}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: McColors.textFg2,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          McSpacing.md,
                          McSpacing.xs,
                          McSpacing.md,
                          McSpacing.md,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              ReceiptDetailScreen.route(sale.id),
                            ),
                            icon: const Icon(Icons.receipt_long, size: 16),
                            label: const Text('Ver comprobante'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: McColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalSaleCard extends StatelessWidget {
  final CompletedSale sale;

  const _LocalSaleCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final time =
        '${sale.completedAt.hour.toString().padLeft(2, '0')}:${sale.completedAt.minute.toString().padLeft(2, '0')}';
    return ExpansionTile(
      leading: const CircleAvatar(
        backgroundColor: McColors.textSecondaryLight,
        foregroundColor: Colors.white,
        child: Icon(Icons.sync, size: 16),
      ),
      title: Text(sale.finalAmount.formatted,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$time — ${sale.customerName} — (pendiente sync)'),
      children: sale.items
          .map((item) => ListTile(
                dense: true,
                title: Text(item.productName),
                trailing: Text(
                  '${item.quantity} × ${item.unitPrice.formatted}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ))
          .toList(),
    );
  }
}

/// Venta completada — snapshot inmutable para el historial local.
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
