import 'package:mc_domain/mc_domain.dart';

/// Fuerza una recarga fresca de las estadísticas del dashboard.
///
/// Semánticamente distinto de [GetAdminDashboardStatsUseCase]: se usa
/// exclusivamente cuando el usuario dispara un refresh manual o cuando
/// el auto-refresh del timer dispara la recarga.
///
/// Delega igualmente en [DashboardRepository.getDashboardStats], que
/// siempre consulta el backend y nunca usa caché local.
class RefreshDashboardUseCase {
  final DashboardRepository _repository;

  RefreshDashboardUseCase(this._repository);

  Future<DashboardStats> execute() => _repository.getDashboardStats();
}
