import 'package:mc_domain/mc_domain.dart';

class ListJobsUseCase {
  final WebDataRepository _repository;

  ListJobsUseCase(this._repository);

  Future<PaginatedResult<WebJob>> execute({
    String? status,
    String? sourceId,
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.listJobs(
      status: status,
      sourceId: sourceId,
      page: page,
      pageSize: pageSize,
    );
  }
}
