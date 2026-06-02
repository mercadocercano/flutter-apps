import 'package:mc_domain/mc_domain.dart';

/// Obtiene las estadísticas consolidadas del dashboard de administración.
///
/// Delega en [DashboardRepository.getDashboardStats] que ejecuta todos
/// los requests en paralelo y aísla errores por sección.
class GetAdminDashboardStatsUseCase {
  final DashboardRepository _repository;

  GetAdminDashboardStatsUseCase(this._repository);

  Future<DashboardStats> execute() => _repository.getDashboardStats();
}
