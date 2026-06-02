import 'package:mc_domain/mc_domain.dart';

/// Verifica el estado de salud de todos los servicios del marketplace.
///
/// Delega en [DashboardRepository.getServicesHealth] que hace ping
/// en paralelo y nunca propaga excepción: servicios caídos se reportan
/// como [ServiceStatus.offline].
class GetServicesHealthUseCase {
  final DashboardRepository _repository;

  GetServicesHealthUseCase(this._repository);

  Future<List<ServiceHealth>> execute() => _repository.getServicesHealth();
}
