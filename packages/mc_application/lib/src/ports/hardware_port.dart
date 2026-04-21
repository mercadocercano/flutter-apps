/// Puerto de hardware — scanner, impresora, balanza.
/// Cada adaptador implementa lo que su plataforma soporta.
abstract interface class ScannerPort {
  Future<String?> scanBarcode();
  bool get isAvailable;
}

abstract interface class PrinterPort {
  Future<bool> isConnected();
  Future<List<PrinterDevice>> discoverDevices();
  Future<void> connect(String deviceId);
  Future<void> printReceipt(ReceiptData receipt);
  Future<void> disconnect();
}

abstract interface class ScalePort {
  Future<double> readWeight();
  bool get isConnected;
  Stream<double> get weightStream;
}

/// Dispositivo de impresora descubierto.
class PrinterDevice {
  final String id;
  final String name;
  final String type; // bluetooth, usb, network

  const PrinterDevice({
    required this.id,
    required this.name,
    required this.type,
  });
}

/// Datos para imprimir un ticket.
class ReceiptData {
  final String storeName;
  final List<ReceiptItem> items;
  final double total;
  final double? discount;
  final double paid;
  final double change;
  final DateTime date;

  const ReceiptData({
    required this.storeName,
    required this.items,
    required this.total,
    this.discount,
    required this.paid,
    required this.change,
    required this.date,
  });
}

class ReceiptItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
}
