import 'package:mc_domain/mc_domain.dart';

/// Estados de la pantalla de detalle de comprobante.
sealed class ReceiptState {
  const ReceiptState();
}

class ReceiptInitial extends ReceiptState {
  const ReceiptInitial();
}

class ReceiptLoading extends ReceiptState {
  const ReceiptLoading();
}

class ReceiptLoaded extends ReceiptState {
  final SaleReceipt receipt;

  /// true mientras se ejecuta una acción de impresión (PDF o ticket),
  /// para deshabilitar botones y mostrar progreso sin perder el detalle.
  final bool isPrinting;

  const ReceiptLoaded(this.receipt, {this.isPrinting = false});

  ReceiptLoaded copyWith({bool? isPrinting}) =>
      ReceiptLoaded(receipt, isPrinting: isPrinting ?? this.isPrinting);
}

class ReceiptError extends ReceiptState {
  final String message;
  const ReceiptError(this.message);
}
