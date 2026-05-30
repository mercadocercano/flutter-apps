import 'package:mc_domain/mc_domain.dart';

/// Página de resultados paginados.
class BrandPage {
  final List<Brand> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const BrandPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < totalCount;
}

/// Puerto de marcas — CRUD para el tenant.
abstract interface class BrandPort {
  Future<BrandPage> listBrands({int page = 1, int pageSize = 20});
  Future<Brand> getBrand(String brandId);
  Future<Brand> createBrand({required String name, String? description, String? color});
  Future<Brand> updateBrand({
    required String brandId,
    required String name,
    String? description,
    String status = 'active',
    String? color,
  });
  Future<void> deleteBrand(String brandId);
}
