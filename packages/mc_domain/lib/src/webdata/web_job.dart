import 'package:equatable/equatable.dart';

import 'web_job_status.dart';

/// Job de scraping asociado a una WebSource.
///
/// Registra el ciclo de vida de una ejecución de scraping: inicio, progreso,
/// productos encontrados y finalización (exitosa, fallida o cancelada).
class WebJob extends Equatable {
  final String id;
  final String sourceId;
  final WebJobStatus status;

  /// Progreso de 0.0 a 1.0 (1.0 = 100% completado).
  final double progress;

  /// Cantidad de productos encontrados hasta el momento.
  final int productsFound;

  /// Log de error cuando status == failed.
  final String? errorLog;

  final DateTime startedAt;

  /// Fecha de finalización. Null mientras el job está running.
  final DateTime? finishedAt;

  const WebJob({
    required this.id,
    required this.sourceId,
    required this.status,
    required this.progress,
    required this.productsFound,
    this.errorLog,
    required this.startedAt,
    this.finishedAt,
  });

  /// Indica si el job está actualmente en ejecución.
  bool get isActive => status == WebJobStatus.running;

  /// Duración en segundos si el job finalizó, null si aún está running.
  int? get durationSeconds => finishedAt?.difference(startedAt).inSeconds;

  WebJob copyWith({
    String? id,
    String? sourceId,
    WebJobStatus? status,
    double? progress,
    int? productsFound,
    String? errorLog,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return WebJob(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      productsFound: productsFound ?? this.productsFound,
      errorLog: errorLog ?? this.errorLog,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sourceId,
        status,
        progress,
        productsFound,
        errorLog,
        startedAt,
        finishedAt,
      ];
}
