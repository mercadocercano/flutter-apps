import '../../../core/api/kong_client.dart';
import '../domain/models/brand_model.dart';
import 'brands_api.dart';

class BrandsRepository {
  late final BrandsApi _api;

  BrandsRepository(KongClient kong) : _api = BrandsApi(kong);

  Future<List<Brand>> getAll({
    String? search,
    bool? verified,
    bool? active,
  }) async {
    final items = await _api.getAll(
      search: search,
      verified: verified,
      active: active,
    );
    return items.map(Brand.fromJson).toList();
  }

  Future<Brand> create(Brand brand) async {
    final json = await _api.create(brand.toJson());
    return Brand.fromJson(json);
  }

  Future<Brand> update(String id, Brand brand) async {
    final json = await _api.update(id, brand.toJson());
    return Brand.fromJson(json);
  }

  Future<void> delete(String id) => _api.delete(id);

  Future<void> verify(String id) => _api.verify(id);
}
