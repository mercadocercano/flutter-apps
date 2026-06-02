import 'package:mc_domain/mc_domain.dart';

class BulkAssignBusinessTypeUseCase {
  final WebDataRepository _repository;

  BulkAssignBusinessTypeUseCase(this._repository);

  Future<void> execute(List<String> ids, String businessTypeId) =>
      _repository.bulkAssignBusinessType(ids, businessTypeId);
}
