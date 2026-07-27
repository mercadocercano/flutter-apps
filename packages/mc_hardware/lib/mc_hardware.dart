/// Package mc_hardware de Mercado Cercano.
///
/// Adaptadores de hardware comercial (impresora térmica, scanner, balanza)
/// que implementan los ports definidos en `mc_application`.
library;

// Impresora térmica ESC/POS
export 'src/printer/esc_pos_receipt_formatter.dart';
export 'src/printer/bluetooth_thermal_printer_adapter.dart';
export 'src/printer/receipt_mapper.dart';
