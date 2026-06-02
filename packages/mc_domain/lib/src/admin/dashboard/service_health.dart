import 'package:equatable/equatable.dart';

import 'service_status.dart';

/// Value object que representa la salud de un servicio del marketplace.
///
/// `service` identifica el nombre lógico del servicio (ej. "kong", "iam",
/// "pim", "webdata", "ai-gateway"). `latencyMs` es null cuando el servicio
/// está offline y no pudo medirse la latencia.
class ServiceHealth extends Equatable {
  final String service;
  final ServiceStatus status;

  /// Latencia en milisegundos de la última verificación. Null si offline.
  final int? latencyMs;

  const ServiceHealth({
    required this.service,
    required this.status,
    this.latencyMs,
  });

  /// Indica si el servicio está completamente operativo.
  bool get isOnline => status == ServiceStatus.online;

  /// Indica si el servicio tiene algún problema (degradado u offline).
  bool get hasIssue => status != ServiceStatus.online;

  @override
  List<Object?> get props => [service, status, latencyMs];
}
