import 'package:equatable/equatable.dart';

/// Value object con las métricas del módulo Web Data para el dashboard.
///
/// Agrega contadores de fuentes activas, jobs en ejecución y productos
/// scrapeados hoy para dar visibilidad del estado del pipeline de scraping.
class WebDataStats extends Equatable {
  final int activeSources;
  final int runningJobs;
  final int productsScrapedToday;

  const WebDataStats({
    required this.activeSources,
    required this.runningJobs,
    required this.productsScrapedToday,
  });

  @override
  List<Object?> get props => [
        activeSources,
        runningJobs,
        productsScrapedToday,
      ];
}
