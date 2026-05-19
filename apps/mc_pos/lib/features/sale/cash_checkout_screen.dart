import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import '../../constants/pos_constants.dart';
import '../../widgets/pos/pos_top_bar.dart';
import '../../widgets/pos/product_card_pos.dart' show fmtAR;

/// Pantalla de cobro en efectivo — full-screen en mobile.
class CashCheckoutScreen extends StatefulWidget {
  final PosSale sale;
  final void Function(Customer, PaymentMethod, Money) onComplete;

  const CashCheckoutScreen({
    super.key,
    required this.sale,
    required this.onComplete,
  });

  @override
  State<CashCheckoutScreen> createState() => _CashCheckoutScreenState();
}

class _CashCheckoutScreenState extends State<CashCheckoutScreen> {
  late final TextEditingController _receivedController;
  double _received = 0;
  List<PaymentMethod> _methods = [];
  PaymentMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _received = widget.sale.finalAmount.amount;
    _receivedController = TextEditingController(
      text: widget.sale.finalAmount.amount.toStringAsFixed(0),
    );
    _receivedController.addListener(_onReceivedChanged);
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _receivedController.removeListener(_onReceivedChanged);
    _receivedController.dispose();
    super.dispose();
  }

  void _onReceivedChanged() {
    setState(() {
      _received = double.tryParse(_receivedController.text) ?? 0;
    });
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await context.read<PaymentMethodPort>().listPaymentMethods();
      if (!mounted) return;
      setState(() {
        _methods = methods;
        _selectedMethod = methods.where((m) => m.isCash).firstOrNull ??
            (methods.isNotEmpty ? methods.first : null);
      });
    } catch (_) {
      // Si falla, se usa efectivo por defecto
    }
  }

  void _setReceived(double amount) {
    _receivedController.text = amount.toStringAsFixed(0);
    setState(() => _received = amount);
  }

  void _confirm() {
    final customer = const Customer(
      id: 'default',
      tenantId: 'demo',
      name: 'Consumidor Final',
    );
    final method = _selectedMethod ??
        (_methods.isNotEmpty
            ? _methods.first
            : const PaymentMethod(
                id: 'cash',
                name: 'Efectivo',
                code: 'cash',
              ));
    widget.onComplete(customer, method, Money.ars(_received));
    Navigator.of(context).pop();
  }

  bool get _canConfirm => _received >= widget.sale.finalAmount.amount;

  @override
  Widget build(BuildContext context) {
    final total = widget.sale.finalAmount.amount;
    final change = _received - total;

    return Scaffold(
      backgroundColor: McColors.backgroundLight,
      body: Column(
        children: [
          PosTopBar(
            title: 'Cobrar',
            subtitle: '${widget.sale.totalItems} producto${widget.sale.totalItems == 1 ? '' : 's'}',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: McColors.textFg2),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Hero total
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: McSpacing.base,
              vertical: 20,
            ),
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  'TOTAL A COBRAR',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: McColors.textFg2,
                    letterSpacing: 0.04 * 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fmtAR(total),
                  style: McTypography.mono(44, color: McColors.primary),
                ),
              ],
            ),
          ),
          Container(height: 1, color: McColors.borderLight),

          // Tabs métodos de pago
          if (_methods.isNotEmpty)
            _PaymentMethodTabs(
              methods: _methods,
              selected: _selectedMethod,
              onSelect: (m) => setState(() => _selectedMethod = m),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(McSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recibido',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: McColors.foregroundLight,
                    ),
                  ),
                  const SizedBox(height: McSpacing.sm),

                  // Campo monto recibido
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: McColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(McSpacing.radiusLg),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: McSpacing.base,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _receivedController,
                            keyboardType: TextInputType.number,
                            style: McTypography.mono(
                              26,
                              color: McColors.foregroundLight,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_received > 0)
                          GestureDetector(
                            onTap: () => _setReceived(0),
                            child: const Icon(
                              Icons.close,
                              color: McColors.textFg2,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: McSpacing.md),

                  // Atajos de denominaciones
                  Text(
                    'Atajos',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: McColors.textFg2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: McSpacing.sm,
                    runSpacing: McSpacing.sm,
                    children: [
                      ...PosConstants.denominations.map(
                        (d) => _DenomChip(
                          label: fmtAR(d.toDouble()),
                          isSelected: _received == d.toDouble(),
                          onTap: () => _setReceived(d.toDouble()),
                        ),
                      ),
                      _DenomChip(
                        label: 'Justo',
                        isSelected: _received == total,
                        onTap: () => _setReceived(total),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Vuelto / Falta
                  if (_received >= total && _received > 0)
                    _VueltoBanner(change: change)
                  else if (_received > 0)
                    _FaltaBanner(falta: total - _received),
                ],
              ),
            ),
          ),

          // CTA confirmar
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
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _canConfirm ? _confirm : null,
                icon: const Icon(Icons.check),
                label: const Text('Confirmar cobro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: McColors.success,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: McColors.mutedLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(McSpacing.radiusLg),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tabs de métodos de pago ───

class _PaymentMethodTabs extends StatelessWidget {
  final List<PaymentMethod> methods;
  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod> onSelect;

  const _PaymentMethodTabs({
    required this.methods,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: McSpacing.base,
          vertical: McSpacing.sm,
        ),
        children: methods.map((m) {
          final isSelected = m.id == selected?.id;
          return Padding(
            padding: const EdgeInsets.only(right: McSpacing.sm),
            child: GestureDetector(
              onTap: () => onSelect(m),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: McSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? McColors.cobaltTint : McColors.mutedLight,
                  border: Border.all(
                    color: isSelected ? McColors.primary : McColors.borderLight,
                  ),
                  borderRadius:
                      BorderRadius.circular(McSpacing.radiusFull),
                ),
                child: Text(
                  m.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? McColors.primary : McColors.textFg2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Chip de denominación ───

class _DenomChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DenomChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: McSpacing.md,
          vertical: McSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? McColors.cobaltTint : Colors.white,
          border: Border.all(
            color: isSelected ? McColors.primary : McColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(McSpacing.radiusMd),
        ),
        child: Text(
          label,
          style: McTypography.mono(
            14,
            color: isSelected ? McColors.primary : McColors.foregroundLight,
          ),
        ),
      ),
    );
  }
}

// ─── Banner vuelto ───

class _VueltoBanner extends StatelessWidget {
  final double change;

  const _VueltoBanner({required this.change});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(McSpacing.md),
      decoration: BoxDecoration(
        color: McColors.successTint,
        border: Border.all(color: McColors.success),
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'VUELTO',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: McColors.success,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            fmtAR(change),
            style: McTypography.mono(22, color: McColors.success),
          ),
        ],
      ),
    );
  }
}

// ─── Banner falta ───

class _FaltaBanner extends StatelessWidget {
  final double falta;

  const _FaltaBanner({required this.falta});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(McSpacing.md),
      decoration: BoxDecoration(
        color: McColors.errorTint,
        border: Border.all(color: McColors.error),
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'FALTA',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: McColors.error,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            fmtAR(falta),
            style: McTypography.mono(22, color: McColors.error),
          ),
        ],
      ),
    );
  }
}
