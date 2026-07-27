import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_hardware/mc_hardware.dart';

import 'pdf_document_printer.dart';
import 'receipt_state.dart';

/// Resultado de una acción de impresión, para que la UI muestre feedback.
class PrintOutcome {
  final bool success;
  final String message;
  const PrintOutcome.ok(this.message) : success = true;
  const PrintOutcome.failed(this.message) : success = false;
}

/// Cubit del detalle de comprobante.
///
/// - Carga el detalle vía [SalePort.getReceipt].
/// - Imprime/comparte el PDF A4 generado por el backend (vía [PdfDocumentPrinter]).
/// - Imprime el ticket térmico ESC/POS (vía [PrinterPort]).
class ReceiptCubit extends Cubit<ReceiptState> {
  final SalePort _salePort;
  final PdfDocumentPrinter _pdfPrinter;
  final PrinterPort? _thermalPrinter;
  final String _storeName;

  ReceiptCubit({
    required SalePort salePort,
    required PdfDocumentPrinter pdfPrinter,
    PrinterPort? thermalPrinter,
    String storeName = 'Mercado Cercano',
  })  : _salePort = salePort,
        _pdfPrinter = pdfPrinter,
        _thermalPrinter = thermalPrinter,
        _storeName = storeName,
        super(const ReceiptInitial());

  bool get hasThermalPrinter => _thermalPrinter != null;

  Future<void> load(String saleId) async {
    emit(const ReceiptLoading());
    try {
      final receipt = await _salePort.getReceipt(saleId);
      emit(ReceiptLoaded(receipt));
    } catch (_) {
      emit(const ReceiptError(
        'No pudimos cargar el comprobante. Verificá tu conexión.',
      ));
    }
  }

  /// Descarga el PDF A4 del backend e invoca el diálogo de impresión nativo.
  Future<PrintOutcome> printPdf() => _runPdf(share: false);

  /// Descarga el PDF A4 del backend y abre la hoja de compartir.
  Future<PrintOutcome> sharePdf() => _runPdf(share: true);

  Future<PrintOutcome> _runPdf({required bool share}) async {
    final current = state;
    if (current is! ReceiptLoaded) {
      return const PrintOutcome.failed('El comprobante no está cargado.');
    }
    emit(current.copyWith(isPrinting: true));
    try {
      // TODO(E18-TramoC-backend): este endpoint lo implementa otro dev en
      // paralelo (`GET /sales/pos/{id}/pdf`). Hasta que esté disponible,
      // downloadReceiptPdf devolverá un 404/501 y caemos al catch de abajo.
      final bytes = await _salePort.downloadReceiptPdf(current.receipt.id);
      final fileName = 'comprobante-${current.receipt.saleNumber}.pdf';
      if (share) {
        await _pdfPrinter.sharePdf(bytes, fileName: fileName);
      } else {
        await _pdfPrinter.printPdf(bytes, documentName: fileName);
      }
      return PrintOutcome.ok(share ? 'PDF listo para compartir.' : 'Enviado a imprimir.');
    } catch (_) {
      return const PrintOutcome.failed(
        'No pudimos generar el PDF. Probá de nuevo en unos segundos.',
      );
    } finally {
      final s = state;
      if (s is ReceiptLoaded) emit(s.copyWith(isPrinting: false));
    }
  }

  /// Imprime el ticket térmico en la impresora ESC/POS conectada.
  /// El POS llama a esto cuando el dispositivo tiene impresora térmica.
  Future<PrintOutcome> printThermalTicket() async {
    final current = state;
    if (current is! ReceiptLoaded) {
      return const PrintOutcome.failed('El comprobante no está cargado.');
    }
    final printer = _thermalPrinter;
    if (printer == null) {
      return const PrintOutcome.failed(
        'No hay impresora térmica configurada en este dispositivo.',
      );
    }
    emit(current.copyWith(isPrinting: true));
    try {
      if (!await printer.isConnected()) {
        return const PrintOutcome.failed('La impresora no está conectada.');
      }
      final data = receiptDataFromSale(current.receipt, storeName: _storeName);
      await printer.printReceipt(data);
      return const PrintOutcome.ok('Ticket impreso.');
    } catch (e) {
      return PrintOutcome.failed('No se pudo imprimir el ticket: $e');
    } finally {
      final s = state;
      if (s is ReceiptLoaded) emit(s.copyWith(isPrinting: false));
    }
  }
}
