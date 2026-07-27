import 'dart:typed_data';

import 'package:mc_domain/mc_domain.dart';

/// Puerto de ventas POS — persistir y consultar ventas.
abstract interface class SalePort {
  Future<PosSale> createSale(PosSale sale);
  Future<List<PosSale>> listSales({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 50,
  });
  Future<PosSale> getSale(String saleId);

  /// Detalle completo del comprobante: ítems, totales, vuelto, medio de pago
  /// y cliente ya resueltos por el backend.
  /// Endpoint: `GET /sales/api/v1/sales/pos/{id}`.
  Future<SaleReceipt> getReceipt(String saleId);

  /// Descarga el PDF A4 del comprobante generado por el backend.
  /// Endpoint: `GET /sales/api/v1/sales/pos/{id}/pdf` (application/pdf).
  ///
  /// Lanza si el endpoint todavía no está disponible (lo implementa otro dev
  /// en paralelo dentro de E18 / Tramo C backend).
  Future<Uint8List> downloadReceiptPdf(String saleId);
}

/// Puerto de ventas local — para operar offline.
abstract interface class LocalSalePort {
  Future<void> savePending(PosSale sale);
  Future<List<PosSale>> getPendingSales();
  Future<void> markSynced(String saleId);
}
