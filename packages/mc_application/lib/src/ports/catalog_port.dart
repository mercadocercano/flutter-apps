import 'package:mc_domain/mc_domain.dart';

/// Página de resultados paginados de productos.
class ProductPage {
  final List<Product> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const ProductPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < totalCount;
}

/// Puerto de catálogo — CRUD de productos del tenant.
abstract interface class CatalogPort {
  Future<ProductPage> listProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? category,
    String? brand,
    ProductStatus? status,
  });

  Future<Product> getProduct(String productId);
  Future<Product?> getProductBySku(String sku);
  Future<Product?> getProductByBarcode(String barcode);
  Future<int> countProducts();

  Future<Product> createProduct({
    required String name,
    String? description,
    String? categoryId,
    String? brandId,
  });

  Future<Product> updateProduct({
    required String productId,
    required String name,
    String? description,
    String? categoryId,
    String? brandId,
    String status,
  });

  Future<void> deleteProduct(String productId);
}

/// Puerto de catálogo local — para offline-first.
abstract interface class LocalCatalogPort {
  Future<void> syncFromRemote(List<Product> products);
  Future<List<Product>> searchLocal(String query);
  Future<Product?> findBySku(String sku);
  Future<DateTime?> lastSyncAt();
}
