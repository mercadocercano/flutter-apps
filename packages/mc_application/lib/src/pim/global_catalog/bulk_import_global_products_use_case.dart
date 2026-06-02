import 'package:mc_domain/mc_domain.dart';

class BulkImportGlobalProductsUseCase {
  final GlobalProductRepository _repository;

  BulkImportGlobalProductsUseCase(this._repository);

  Future<BulkImportResult> execute(List<Map<String, dynamic>> rows) =>
      _repository.bulkImport(rows);
}
