import 'package:equatable/equatable.dart';

/// Value object con las métricas del dashboard Web Data.
///
/// Agrega contadores de fuentes, jobs y productos para mostrar
/// el estado general del módulo de scraping.
class WebDataDashboardStats extends Equatable {
  final int activeSources;
  final int inactiveSources;
  final int jobsToday;
  final int totalProducts;

  /// Tasa de éxito de jobs (0.0 = 0%, 1.0 = 100%).
  final double successRate;

  const WebDataDashboardStats({
    required this.activeSources,
    required this.inactiveSources,
    required this.jobsToday,
    required this.totalProducts,
    required this.successRate,
  });

  /// Total de fuentes (activas + inactivas).
  int get totalSources => activeSources + inactiveSources;

  /// Tasa de éxito expresada como porcentaje entero (0–100).
  int get successRatePercent => (successRate * 100).round();

  @override
  List<Object?> get props => [
        activeSources,
        inactiveSources,
        jobsToday,
        totalProducts,
        successRate,
      ];
}
