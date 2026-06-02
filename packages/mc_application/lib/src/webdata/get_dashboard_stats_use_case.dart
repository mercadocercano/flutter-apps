import 'package:mc_domain/mc_domain.dart';

class GetDashboardStatsUseCase {
  final WebDataRepository _repository;

  GetDashboardStatsUseCase(this._repository);

  Future<WebDataDashboardStats> execute() => _repository.getDashboardStats();
}
