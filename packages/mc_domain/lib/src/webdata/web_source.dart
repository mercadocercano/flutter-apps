import 'package:equatable/equatable.dart';

import 'web_source_status.dart';

/// Fuente de datos web configurada para scraping de productos.
///
/// Cada WebSource define un sitio externo del cual se extraen productos,
/// su estado de activación, la expresión cron de schedule y los tipos
/// de comercio a los que aplican los productos scrapeados.
class WebSource extends Equatable {
  final String id;
  final String name;
  final String url;
  final WebSourceStatus status;

  /// Expresión cron para ejecución automática. Null = solo ejecución manual.
  final String? schedule;

  /// IDs de business_types a los que se asocian los productos de esta fuente.
  final List<String> businessTypeIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  const WebSource({
    required this.id,
    required this.name,
    required this.url,
    required this.status,
    this.schedule,
    this.businessTypeIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Indica si la fuente puede iniciar un job nuevo.
  bool get canTrigger => status != WebSourceStatus.running;

  WebSource copyWith({
    String? id,
    String? name,
    String? url,
    WebSourceStatus? status,
    String? schedule,
    List<String>? businessTypeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WebSource(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      status: status ?? this.status,
      schedule: schedule ?? this.schedule,
      businessTypeIds: businessTypeIds ?? this.businessTypeIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        url,
        status,
        schedule,
        businessTypeIds,
        createdAt,
        updatedAt,
      ];
}
