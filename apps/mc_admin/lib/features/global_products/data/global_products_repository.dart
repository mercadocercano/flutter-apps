import '../../../core/api/kong_client.dart';
import '../domain/models/global_product_model.dart';
import 'global_products_api.dart';

class GlobalProductsRepository {
  late final GlobalProductsApi _api;

  GlobalProductsRepository(KongClient kong) : _api = GlobalProductsApi(kong);

  Future<GlobalProductsPage> getAll({
    String? search,
    String? businessType,
    bool? isVerified,
    bool? hasImage,
    int page = 1,
    int pageSize = 50,
  }) async {
    final json = await _api.getAll(
      search: search,
      businessType: businessType,
      isVerified: isVerified,
      hasImage: hasImage,
      page: page,
      pageSize: pageSize,
    );
    return GlobalProductsPage.fromJson(json);
  }

  Future<GlobalProduct> getById(String id) async {
    final json = await _api.getById(id);
    return GlobalProduct.fromJson(json);
  }

  Future<List<String>> getBusinessTypes() => _api.getBusinessTypes();
}
