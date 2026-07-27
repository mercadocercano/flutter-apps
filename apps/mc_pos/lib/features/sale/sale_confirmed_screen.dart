import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_design_system/mc_design_system.dart';
import '../../widgets/pos/product_card_pos.dart' show fmtAR;
import 'receipt/receipt_detail_screen.dart';

/// Pantalla de confirmación de venta exitosa.
class SaleConfirmedScreen extends StatelessWidget {
  /// Número de comprobante legible que se muestra al cajero.
  final String saleNumber;

  /// ID de la venta (UUID) — usado para abrir el detalle/imprimir.
  final String saleId;
  final double total;
  final double received;
  final String paymentMethodName;
  final VoidCallback onNewSale;

  const SaleConfirmedScreen({
    super.key,
    required this.saleNumber,
    required this.saleId,
    required this.total,
    required this.received,
    required this.paymentMethodName,
    required this.onNewSale,
  });

  @override
  Widget build(BuildContext context) {
    final change = received - total;

    return Scaffold(
      backgroundColor: McColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior mínima
            Container(
              height: 40,
              color: Colors.white,
              child: const Divider(height: 1, color: McColors.borderLight),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // Ícono animado de éxito
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      builder: (ctx, v, child) => Transform.scale(
                        scale: v,
                        child: Opacity(
                          opacity: v.clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: McColors.successTint,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: McColors.success.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 48,
                          color: McColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      '¡Cobrado!',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: McColors.foregroundLight,
                        letterSpacing: -0.02 * 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Venta #$saleNumber',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: McColors.textFg2,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Card resumen
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: McSpacing.lg,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: McColors.borderLight),
                          borderRadius:
                              BorderRadius.circular(McSpacing.radiusLg),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _SaleRow(
                              'Total cobrado',
                              fmtAR(total),
                              isMono: true,
                              isPrimary: true,
                            ),
                            const Divider(
                              color: McColors.mutedLight,
                              height: 24,
                            ),
                            _SaleRow('Método', paymentMethodName),
                            const SizedBox(height: McSpacing.xs),
                            _SaleRow('Recibido', fmtAR(received)),
                            if (change > 0) ...[
                              const SizedBox(height: McSpacing.xs),
                              _SaleRow(
                                'Vuelto',
                                fmtAR(change),
                                isSuccess: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Acciones secundarias
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: McSpacing.lg,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  ReceiptDetailScreen.route(saleId),
                                );
                              },
                              icon: const Icon(Icons.print_outlined, size: 18),
                              label: const Text('Imprimir'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: McColors.textFg2,
                              ),
                            ),
                          ),
                          const SizedBox(width: McSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Venta #$saleNumber · Total: ${fmtAR(total)}'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_outlined, size: 18),
                              label: const Text('WhatsApp'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: McColors.textFg2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // CTA nueva venta
            Padding(
              padding: const EdgeInsets.fromLTRB(
                McSpacing.base,
                McSpacing.base,
                McSpacing.base,
                20,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onNewSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: McColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(McSpacing.radiusLg),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Nueva venta'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;
  final bool isPrimary;
  final bool isSuccess;

  const _SaleRow(
    this.label,
    this.value, {
    this.isMono = false,
    this.isPrimary = false,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = isPrimary
        ? McColors.primary
        : isSuccess
            ? McColors.success
            : McColors.foregroundLight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: McColors.textFg2,
          ),
        ),
        isMono
            ? Text(
                value,
                style: McTypography.mono(
                  isPrimary ? 16 : 13,
                  color: valueColor,
                ),
              )
            : Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
      ],
    );
  }
}
