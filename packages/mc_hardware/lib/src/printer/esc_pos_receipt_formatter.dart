import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:mc_application/mc_application.dart';

/// Ancho del papel de la impresora térmica.
enum ThermalPaperWidth {
  mm58(PaperSize.mm58, 32),
  mm80(PaperSize.mm80, 48);

  final PaperSize paperSize;

  /// Caracteres por línea en fuente A.
  final int charsPerLine;

  const ThermalPaperWidth(this.paperSize, this.charsPerLine);
}

/// Convierte un [ReceiptData] del dominio en una lista de bytes ESC/POS lista
/// para enviar a una impresora térmica.
///
/// Toda la lógica de formato del ticket (ancho angosto, alineación, totales)
/// vive acá, desacoplada del transporte (Bluetooth/USB/red).
class EscPosReceiptFormatter {
  final ThermalPaperWidth paperWidth;
  final String currencySymbol;

  const EscPosReceiptFormatter({
    this.paperWidth = ThermalPaperWidth.mm58,
    this.currencySymbol = r'$',
  });

  Future<List<int>> build(ReceiptData receipt) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperWidth.paperSize, profile);
    final bytes = <int>[];

    // ─── Encabezado ───
    bytes.addAll(generator.text(
      receipt.storeName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(generator.text(
      _formatDate(receipt.date),
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.hr());

    // ─── Ítems ───
    for (final item in receipt.items) {
      // Línea 1: nombre del producto (puede partirse en varias líneas).
      bytes.addAll(generator.text(item.name));
      // Línea 2: cantidad x precio .......... subtotal
      bytes.addAll(generator.row([
        PosColumn(
          text: '${item.quantity} x ${_money(item.unitPrice)}',
          width: 7,
        ),
        PosColumn(
          text: _money(item.subtotal),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(generator.hr());

    // ─── Totales ───
    if (receipt.discount != null && receipt.discount! > 0) {
      bytes.addAll(_totalRow(generator, 'Descuento', -receipt.discount!));
    }
    bytes.addAll(_totalRow(
      generator,
      'TOTAL',
      receipt.total,
      emphasize: true,
    ));
    bytes.addAll(_totalRow(generator, 'Pagado', receipt.paid));
    if (receipt.change > 0) {
      bytes.addAll(_totalRow(generator, 'Vuelto', receipt.change));
    }

    // ─── Pie ───
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text(
      '¡Gracias por su compra!',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }

  List<int> _totalRow(
    Generator generator,
    String label,
    double amount, {
    bool emphasize = false,
  }) {
    final style = PosStyles(
      bold: emphasize,
      height: emphasize ? PosTextSize.size2 : PosTextSize.size1,
      width: emphasize ? PosTextSize.size2 : PosTextSize.size1,
    );
    return generator.row([
      PosColumn(text: label, width: 6, styles: style),
      PosColumn(
        text: _money(amount),
        width: 6,
        styles: style.copyWith(align: PosAlign.right),
      ),
    ]);
  }

  String _money(double amount) {
    final negative = amount < 0;
    final abs = amount.abs();
    final whole = abs.truncate();
    final decimals = ((abs - whole) * 100).round().toString().padLeft(2, '0');
    final wholeStr = whole.toString();
    // Separador de miles con punto (formato argentino).
    final buffer = StringBuffer();
    for (var i = 0; i < wholeStr.length; i++) {
      if (i > 0 && (wholeStr.length - i) % 3 == 0) buffer.write('.');
      buffer.write(wholeStr[i]);
    }
    return '${negative ? '-' : ''}$currencySymbol$buffer,$decimals';
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
