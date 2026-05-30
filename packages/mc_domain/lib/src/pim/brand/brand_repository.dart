import '../../iam/paginated_result.dart';
import 'marketplace_brand.dart';
import 'brand_params.dart';

/// Puerto de repositorio para marcas del marketplace.
/// Implementado en mc_infrastructure por MarketplaceBrandRepositoryImpl.
abstract interface class MarketplaceBrandRepository {
  Future<PaginatedResult<MarketplaceBrand>> getAll(
    int page,
    int pageSize, {
    String? name,
    BrandVerificationStatus? verificationStatus,
    bool? isActive,
  });

  Future<MarketplaceBrand> getById(String id);

  Future<MarketplaceBrand> create(CreateBrandParams params);

  Future<MarketplaceBrand> update(String id, UpdateBrandParams params);

  Future<void> delete(String id);

  Future<MarketplaceBrand> verify(String id);

  Future<MarketplaceBrand> unverify(String id);
}
