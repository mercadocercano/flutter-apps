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
}

/// Puerto de ventas local — para operar offline.
abstract interface class LocalSalePort {
  Future<void> savePending(PosSale sale);
  Future<List<PosSale>> getPendingSales();
  Future<void> markSynced(String saleId);
}
