import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import 'sales_history_screen.dart';
import '../../widgets/pos/pos_top_bar.dart';
import '../../widgets/pos/denomination_row.dart';
import '../../widgets/pos/difference_banner.dart';
import '../../widgets/pos/product_card_pos.dart' show fmtAR;
import '../../constants/pos_constants.dart';
import '../../widgets/pos/pos_modal.dart';

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
  // Cantidades por denominación: índice = PosConstants.denominations
  late List<int> _denomQtys;

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


  Money get _cashExpected => _salesByMethod['Efectivo'] ?? Money.zero;

  @override
  void initState() {
    super.initState();
    _denomQtys = List.filled(PosConstants.denominations.length, 0);
  }

  double get _countedTotal {
    double total = 0;
    for (int i = 0; i < PosConstants.denominations.length; i++) {
      total += PosConstants.denominations[i] * _denomQtys[i];
    }
    return total;
  }

  @override
  void dispose() {
    _cashCountController.dispose();
    super.dispose();
  }

  void _confirmClose() {
    showPosConfirm(
      context: context,
      title: '¿Cerrar la caja?',
      message: 'Se va a registrar el cierre. Las ventas del día quedan guardadas.',
      confirmLabel: 'Cerrar caja',
      confirmColor: McColors.error,
    ).then((confirmed) {
      if (confirmed && mounted) widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${now.day}/${now.month}/${now.year}';
    final counted = _countedTotal;

    return Scaffold(
      backgroundColor: McColors.backgroundLight,
      body: Column(
        children: [
          PosTopBar(
            title: 'Cierre de caja',
            subtitle: 'Hoy · $dateLabel',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: McColors.textFg2),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(McSpacing.base),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner sistema
                    Container(
                      decoration: BoxDecoration(
                        color: McColors.cobaltTint,
                        border: Border.all(color: McColors.primary),
                        borderRadius:
                            BorderRadius.circular(McSpacing.radiusLg),
                      ),
                      padding: const EdgeInsets.all(McSpacing.base),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SEGÚN EL SISTEMA (EFECTIVO)',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: McColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fmtAR(_cashExpected.amount),
                            style: McTypography.mono(28, color: McColors.primary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.sales.length} ventas en efectivo',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: McColors.textFg2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: McSpacing.lg),

                    // Denominaciones
                    Text(
                      'Conteo por denominación',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: McColors.foregroundLight,
                      ),
                    ),
                    const SizedBox(height: McSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: McColors.borderLight),
                        borderRadius:
                            BorderRadius.circular(McSpacing.radiusLg),
                      ),
                      padding: const EdgeInsets.all(McSpacing.base),
                      child: Column(
                        children: PosConstants.denominations
                            .asMap()
                            .entries
                            .map((e) => DenominationRow(
                                  denomination: e.value,
                                  qty: _denomQtys[e.key],
                                  onQtyChanged: (qty) => setState(
                                      () => _denomQtys[e.key] = qty),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: McSpacing.lg),

                    // Banner diferencia
                    DifferenceBanner(
                      system: _cashExpected.amount,
                      counted: counted,
                    ),
                    const SizedBox(height: McSpacing.xl),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(
              McSpacing.base,
              McSpacing.md,
              McSpacing.base,
              20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: McColors.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: McSpacing.sm),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed:
                        widget.sales.isEmpty ? null : _confirmClose,
                    icon: const Icon(Icons.lock, size: 18),
                    label: const Text('Cerrar caja'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: McColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(McSpacing.radiusLg),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

