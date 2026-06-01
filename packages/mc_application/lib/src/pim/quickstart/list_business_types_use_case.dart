import 'package:mc_domain/mc_domain.dart';

class ListBusinessTypesUseCase {
  final QuickstartRepository _repository;

  ListBusinessTypesUseCase(this._repository);

  Future<PaginatedResult<BusinessType>> execute({
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.listBusinessTypes(
      isActive: isActive,
      page: page,
      pageSize: pageSize,
    );
  }
}
