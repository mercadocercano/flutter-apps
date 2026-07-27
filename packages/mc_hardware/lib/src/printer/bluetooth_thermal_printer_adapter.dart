import 'package:mc_application/mc_application.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'esc_pos_receipt_formatter.dart';

/// Adapter de impresora térmica Bluetooth (SPP) que implementa [PrinterPort].
///
/// Transporte: `print_bluetooth_thermal` (Bluetooth clásico — el estándar de
/// las impresoras térmicas económicas 58/80mm usadas en comercios de barrio).
/// Formato: [EscPosReceiptFormatter] (genera los bytes ESC/POS).
///
/// El [PrinterPort] desacopla esto del resto de la app: para soportar WiFi/USB
/// más adelante se agrega otro adapter sin tocar presentación ni dominio.
class BluetoothThermalPrinterAdapter implements PrinterPort {
  final EscPosReceiptFormatter formatter;

  /// Nombre del comercio que se imprime en la cabecera del ticket.
  final String storeName;

  String? _connectedDeviceId;

  BluetoothThermalPrinterAdapter({
    required this.storeName,
    ThermalPaperWidth paperWidth = ThermalPaperWidth.mm58,
  }) : formatter = EscPosReceiptFormatter(paperWidth: paperWidth);

  @override
  Future<bool> isConnected() async {
    if (_connectedDeviceId == null) return false;
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<PrinterDevice>> discoverDevices() async {
    final enabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!enabled) {
      throw const PrinterException('Bluetooth está apagado.');
    }
    final paired = await PrintBluetoothThermal.pairedBluetooths;
    return paired
        .map((b) => PrinterDevice(
              id: b.macAdress,
              name: b.name,
              type: 'bluetooth',
            ))
        .toList();
  }

  @override
  Future<void> connect(String deviceId) async {
    final ok = await PrintBluetoothThermal.connect(macPrinterAddress: deviceId);
    if (!ok) {
      throw PrinterException('No se pudo conectar con la impresora ($deviceId).');
    }
    _connectedDeviceId = deviceId;
  }

  @override
  Future<void> printReceipt(ReceiptData receipt) async {
    if (!await isConnected()) {
      throw const PrinterException('La impresora no está conectada.');
    }
    final bytes = await formatter.build(receipt);
    final ok = await PrintBluetoothThermal.writeBytes(bytes);
    if (!ok) {
      throw const PrinterException('Falló el envío a la impresora.');
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } finally {
      _connectedDeviceId = null;
    }
  }
}

/// Error de impresión legible para mostrar al usuario.
class PrinterException implements Exception {
  final String message;
  const PrinterException(this.message);

  @override
  String toString() => message;
}
