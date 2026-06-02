import 'dashboard_stats.dart';
import 'service_health.dart';

/// Puerto de repositorio para el dashboard de administración.
///
/// Implementado en mc_infrastructure por DashboardRepositoryImpl.
/// Todas las llamadas HTTP van a través de Kong.
///
/// Los métodos deben ejecutar requests en paralelo (Future.wait) y
/// retornar datos parciales cuando algún servicio falla, nunca propagar
/// la excepción al llamador.
abstract interface class DashboardRepository {
  /// Obtiene las estadísticas consolidadas de todos los módulos.
  ///
  /// Ejecuta los requests a IAM, PIM, Web Data y Quickstart en paralelo.
  /// Si un módulo falla, la sección correspondiente en [DashboardStats]
  /// queda como null. El campo [DashboardStats.loadedAt] refleja el
  /// momento de resolución de todos los futures.
  Future<DashboardStats> getDashboardStats();

  /// Verifica el estado de salud de cada servicio del marketplace.
  ///
  /// Hace ping a los health endpoints de Kong, IAM, PIM, WebData y
  /// AI Gateway en paralelo. Nunca lanza excepción: un servicio que
  /// no responde se reporta como [ServiceStatus.offline].
  Future<List<ServiceHealth>> getServicesHealth();
}
