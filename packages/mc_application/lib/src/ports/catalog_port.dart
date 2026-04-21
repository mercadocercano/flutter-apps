import 'package:mc_domain/mc_domain.dart';

/// Puerto de catálogo — CRUD de productos del tenant.
abstract interface class CatalogPort {
  Future<List<Product>> listProducts({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? category,
    String? brand,
    ProductStatus? status,
  });

  Future<Product> getProduct(String productId);
  Future<Product?> getProductBySku(String sku);
  Future<Product?> getProductByBarcode(String barcode);
  Future<int> countProducts();
}

/// Puerto de catálogo local — para offline-first.
abstract interface class LocalCatalogPort {
  Future<void> syncFromRemote(List<Product> products);
  Future<List<Product>> searchLocal(String query);
  Future<Product?> findBySku(String sku);
  Future<DateTime?> lastSyncAt();
}
