/// Puerto de stock — consultar y ajustar inventario.
abstract interface class StockPort {
  Future<int> getStockBySku(String sku);
  Future<Map<String, int>> getStockForSkus(List<String> skus);
  Future<void> adjustStock({
    required String sku,
    required double quantity,
    required String entryType,
    String? notes,
  });

  /// Registra la carga inicial de stock de un producto (desde quickstart).
  Future<void> createStockEntry({
    required String variantSku,
    required String productName,
    required int quantity,
  });
}
