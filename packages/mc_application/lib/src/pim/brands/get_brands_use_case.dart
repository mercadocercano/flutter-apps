import 'package:mc_domain/mc_domain.dart';

class GetBrandsUseCase {
  final MarketplaceBrandRepository _repository;

  GetBrandsUseCase(this._repository);

  Future<PaginatedResult<MarketplaceBrand>> execute(
    int page,
    int pageSize, {
    String? name,
    BrandVerificationStatus? verificationStatus,
    bool? isActive,
  }) {
    return _repository.getAll(
      page,
      pageSize,
      name: name,
      verificationStatus: verificationStatus,
      isActive: isActive,
    );
  }
}
