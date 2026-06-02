import 'package:equatable/equatable.dart';

import 'iam_stats.dart';
import 'pim_stats.dart';
import 'quickstart_stats.dart';
import 'service_health.dart';
import 'service_status.dart';
import 'web_data_stats.dart';

/// Aggregate root del dashboard de administración.
///
/// Consolida métricas de todos los módulos del marketplace en un único
/// objeto. Cada sección puede ser null cuando el servicio correspondiente
/// falló al cargar — esto permite mostrar datos parciales sin bloquear
/// la vista completa del dashboard.
class DashboardStats extends Equatable {
  final IamStats? iam;
  final PimStats? pim;
  final WebDataStats? webData;
  final QuickstartStats? quickstart;
  final List<ServiceHealth> services;

  /// Momento en que se cargaron los datos del dashboard.
  final DateTime loadedAt;

  const DashboardStats({
    this.iam,
    this.pim,
    this.webData,
    this.quickstart,
    required this.services,
    required this.loadedAt,
  });

  /// Indica si todos los servicios monitoreados están online.
  bool get allServicesOnline =>
      services.every((s) => s.status == ServiceStatus.online);

  /// Indica si al menos una sección de métricas no pudo cargarse.
  bool get hasPartialData =>
      iam == null || pim == null || webData == null || quickstart == null;

  @override
  List<Object?> get props => [
        iam,
        pim,
        webData,
        quickstart,
        services,
        loadedAt,
      ];
}
