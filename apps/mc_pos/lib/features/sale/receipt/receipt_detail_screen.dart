import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../widgets/pos/pos_top_bar.dart';
import '../../../widgets/pos/product_card_pos.dart' show fmtAR;
import 'pdf_document_printer.dart';
import 'receipt_cubit.dart';
import 'receipt_state.dart';

/// Pantalla de detalle de comprobante de venta.
///
/// Consume `GET /sales/pos/{id}` vía [SalePort] y muestra el comprobante
/// completo. Permite imprimir/compartir el PDF A4 y, si hay impresora térmica
/// configurada, imprimir el ticket ESC/POS.
class ReceiptDetailScreen extends StatelessWidget {
  final String saleId;

  const ReceiptDetailScreen({super.key, required this.saleId});

  /// Helper para abrir la pantalla creando su propio Cubit con las dependencias
  /// del árbol (SalePort + impresora térmica opcional).
  static Route<void> route(String saleId) {
    return MaterialPageRoute(
      builder: (context) => BlocProvider(
        create: (_) => ReceiptCubit(
          salePort: context.read<SalePort>(),
          pdfPrinter: const PrintingPdfDocumentPrinter(),
          thermalPrinter: _readPrinterOrNull(context),
        )..load(saleId),
        child: ReceiptDetailScreen(saleId: saleId),
      ),
    );
  }

  static PrinterPort? _readPrinterOrNull(BuildContext context) {
    try {
      return context.read<PrinterPort>();
    } catch (_) {
      return null; // dispositivo sin impresora térmica configurada
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: McColors.backgroundLight,
      body: Column(
        children: [
          PosTopBar(
            title: 'Comprobante',
            subtitle: 'Detalle de la venta',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: McColors.textFg2),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: BlocBuilder<ReceiptCubit, ReceiptState>(
              builder: (context, state) {
                return switch (state) {
                  ReceiptLoading() || ReceiptInitial() =>
                    const Center(child: CircularProgressIndicator()),
                  ReceiptError(message: final m) =>
                    _ErrorView(message: m, saleId: saleId),
                  ReceiptLoaded(receipt: final r, isPrinting: final printing) =>
                    _ReceiptBody(receipt: r, isPrinting: printing),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final String saleId;
  const _ErrorView({required this.message, required this.saleId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(McSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: McColors.error, size: 40),
            const SizedBox(height: McSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: McColors.error),
            ),
            const SizedBox(height: McSpacing.md),
            McButton(
              label: 'Reintentar',
              onPressed: () => context.read<ReceiptCubit>().load(saleId),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  final SaleReceipt receipt;
  final bool isPrinting;

  const _ReceiptBody({required this.receipt, required this.isPrinting});

  Future<void> _runPrint(
    BuildContext context,
    Future<PrintOutcome> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await action();
    messenger.showSnackBar(
      SnackBar(
        content: Text(outcome.message),
        backgroundColor: outcome.success ? McColors.success : McColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReceiptCubit>();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(McSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderCard(receipt: receipt),
                const SizedBox(height: McSpacing.md),
                _ItemsCard(receipt: receipt),
                const SizedBox(height: McSpacing.md),
                _TotalsCard(receipt: receipt),
                const SizedBox(height: McSpacing.lg),
              ],
            ),
          ),
        ),
        _ActionsBar(
          isPrinting: isPrinting,
          hasThermalPrinter: cubit.hasThermalPrinter,
          onPrintPdf: () => _runPrint(context, cubit.printPdf),
          onSharePdf: () => _runPrint(context, cubit.sharePdf),
          onPrintTicket: () => _runPrint(context, cubit.printThermalTicket),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final SaleReceipt receipt;
  const _HeaderCard({required this.receipt});

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} · '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comprobante #${receipt.saleNumber.isEmpty ? receipt.id : receipt.saleNumber}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: McColors.foregroundLight,
            ),
          ),
          const SizedBox(height: McSpacing.xs),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: _formatDateTime(receipt.createdAt),
          ),
          const SizedBox(height: McSpacing.xs),
          _InfoRow(
            icon: Icons.person_outline,
            label: receipt.customerDisplayName,
          ),
          if (receipt.paymentMethodName != null) ...[
            const SizedBox(height: McSpacing.xs),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: receipt.paymentMethodName!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: McColors.textFg2),
        const SizedBox(width: McSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: McColors.textFg2),
          ),
        ),
      ],
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final SaleReceipt receipt;
  const _ItemsCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${receipt.totalItems} producto${receipt.totalItems == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: McColors.foregroundLight,
            ),
          ),
          const SizedBox(height: McSpacing.sm),
          ...receipt.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: McSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName.isEmpty ? item.sku : item.productName,
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          Text(
                            '${item.quantity} × ${fmtAR(item.unitPrice.amount)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: McColors.textFg2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      fmtAR(item.subtotal.amount),
                      style: McTypography.mono(13),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final SaleReceipt receipt;
  const _TotalsCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          if (receipt.hasDiscount) ...[
            _TotalRow(label: 'Subtotal', value: fmtAR(receipt.total.amount)),
            const SizedBox(height: McSpacing.xs),
            _TotalRow(
              label: 'Descuento',
              value: '- ${fmtAR(receipt.discount.amount)}',
            ),
            const Divider(color: McColors.mutedLight, height: 20),
          ],
          _TotalRow(
            label: 'Total',
            value: fmtAR(receipt.finalAmount.amount),
            isPrimary: true,
          ),
          const SizedBox(height: McSpacing.xs),
          _TotalRow(label: 'Pagado', value: fmtAR(receipt.amountPaid.amount)),
          if (receipt.change.isPositive) ...[
            const SizedBox(height: McSpacing.xs),
            _TotalRow(
              label: 'Vuelto',
              value: fmtAR(receipt.change.amount),
              isSuccess: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;
  final bool isSuccess;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isPrimary = false,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPrimary
        ? McColors.primary
        : isSuccess
            ? McColors.success
            : McColors.foregroundLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: McColors.textFg2),
        ),
        Text(value, style: McTypography.mono(isPrimary ? 16 : 13, color: color)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: McColors.borderLight),
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
      ),
      padding: const EdgeInsets.all(McSpacing.base),
      child: child,
    );
  }
}

class _ActionsBar extends StatelessWidget {
  final bool isPrinting;
  final bool hasThermalPrinter;
  final VoidCallback onPrintPdf;
  final VoidCallback onSharePdf;
  final VoidCallback onPrintTicket;

  const _ActionsBar({
    required this.isPrinting,
    required this.hasThermalPrinter,
    required this.onPrintPdf,
    required this.onSharePdf,
    required this.onPrintTicket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: McColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(McSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPrinting)
                const Padding(
                  padding: EdgeInsets.only(bottom: McSpacing.sm),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isPrinting ? null : onSharePdf,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Compartir'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: McColors.textFg2,
                      ),
                    ),
                  ),
                  const SizedBox(width: McSpacing.sm),
                  Expanded(
                    child: hasThermalPrinter
                        ? ElevatedButton.icon(
                            onPressed: isPrinting ? null : onPrintTicket,
                            icon: const Icon(Icons.receipt_long, size: 18),
                            label: const Text('Ticket'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: McColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: isPrinting ? null : onPrintPdf,
                            icon: const Icon(Icons.print_outlined, size: 18),
                            label: const Text('Imprimir PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: McColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
              // Si hay impresora térmica, ofrecer también el PDF como secundario.
              if (hasThermalPrinter) ...[
                const SizedBox(height: McSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isPrinting ? null : onPrintPdf,
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Imprimir PDF A4'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: McColors.textFg2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
