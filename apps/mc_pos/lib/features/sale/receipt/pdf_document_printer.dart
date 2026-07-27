import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Abstracción mínima sobre la plataforma de impresión/compartir de PDF.
/// Permite testear el Cubit sin invocar el plugin `printing` real.
abstract interface class PdfDocumentPrinter {
  /// Abre el diálogo nativo de impresión con el PDF.
  Future<void> printPdf(Uint8List bytes, {String? documentName});

  /// Abre la hoja de "compartir" del sistema con el PDF.
  Future<void> sharePdf(Uint8List bytes, {required String fileName});
}

/// Implementación basada en el paquete `printing`.
class PrintingPdfDocumentPrinter implements PdfDocumentPrinter {
  const PrintingPdfDocumentPrinter();

  @override
  Future<void> printPdf(Uint8List bytes, {String? documentName}) {
    return Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: documentName ?? 'comprobante',
    );
  }

  @override
  Future<void> sharePdf(Uint8List bytes, {required String fileName}) {
    return Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
