import 'package:mc_domain/mc_domain.dart';

class GetPriceHistoryUseCase {
  final WebDataRepository _repository;

  GetPriceHistoryUseCase(this._repository);

  Future<List<PricePoint>> execute(String id) =>
      _repository.getPriceHistory(id);
}
