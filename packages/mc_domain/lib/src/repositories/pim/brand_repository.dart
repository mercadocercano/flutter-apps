import '../../models/pim/brand.dart';

abstract class BrandRepository {
  Future<List<Brand>> getAll();
  Future<Brand?> getById(String id);
  Future<Brand> create(Brand brand);
  Future<Brand> update(Brand brand);
  Future<void> delete(String id);
}