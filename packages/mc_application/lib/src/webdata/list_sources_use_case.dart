import 'package:mc_domain/mc_domain.dart';

class ListSourcesUseCase {
  final WebDataRepository _repository;

  ListSourcesUseCase(this._repository);

  Future<PaginatedResult<WebSource>> execute({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.listSources(
      status: status,
      page: page,
      pageSize: pageSize,
    );
  }
}
