import 'package:mc_domain/mc_domain.dart';

class DeleteBusinessTypeUseCase {
  final QuickstartRepository _repository;

  DeleteBusinessTypeUseCase(this._repository);

  Future<void> execute(String id) => _repository.deleteBusinessType(id);
}
