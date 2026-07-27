# mc_hardware

Adaptadores de hardware comercial para Mercado Cercano. Implementan los **ports**
definidos en `mc_application` (`PrinterPort`, `ScannerPort`, `ScalePort`), de modo
que la app (presentación/dominio) nunca depende de un plugin de hardware concreto.

## Impresora térmica (ESC/POS)

Implementado en `src/printer/`:

- **`EscPosReceiptFormatter`** — convierte un `ReceiptData` (dominio) en bytes
  ESC/POS. Toda la lógica de formato del ticket (ancho 58/80mm, alineación,
  totales, vuelto) vive acá, desacoplada del transporte.
- **`BluetoothThermalPrinterAdapter`** — implementa `PrinterPort` sobre Bluetooth
  clásico (SPP).
- **`receiptDataFromSale`** — mapea `SaleReceipt` (dominio) → `ReceiptData` (port).

### Decisión de librería

| Concern | Librería elegida | Por qué |
|---------|------------------|---------|
| Formato ESC/POS | **`esc_pos_utils_plus`** | Fork mantenido (Dart 3 / null-safety) del abandonado `esc_pos_utils`. Genera bytes con `Generator` + `CapabilityProfile`, soporta `PaperSize.mm58/mm80`, `row`/`PosColumn` para columnas. |
| Transporte | **`print_bluetooth_thermal`** | Bluetooth clásico (SPP), que es el estándar de las impresoras térmicas económicas usadas en comercios de barrio. `esc_pos_printer` solo cubre impresoras de red (WiFi/Ethernet), poco habituales en este segmento. |

Como el formato y el transporte están separados (formatter vs adapter) y todo se
expone detrás de `PrinterPort`, se puede agregar un adapter WiFi/USB más adelante
sin tocar presentación ni dominio.

## Pendiente

- Pantalla de emparejamiento (`discoverDevices` + `connect`) y preferencia de
  ancho de papel (58/80mm) en settings del tenant — ver TODO en `mc_pos/main.dart`.
- Scanner y balanza (ports ya definidos, adapters sin implementar).
