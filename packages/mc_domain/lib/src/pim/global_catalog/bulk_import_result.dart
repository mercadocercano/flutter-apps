import 'package:equatable/equatable.dart';

/// Error ocurrido en una fila durante una importación masiva.
class BulkImportError extends Equatable {
  final int rowNumber;
  final String? sku;
  final String reason;

  const BulkImportError({
    required this.rowNumber,
    this.sku,
    required this.reason,
  });

  @override
  List<Object?> get props => [rowNumber, sku, reason];
}

/// Resultado de una importación masiva de productos globales.
/// Value Object — inmutable, representa el resultado completo de la operación.
class BulkImportResult extends Equatable {
  final int totalRows;
  final int importedCount;
  final int failedCount;
  final List<BulkImportError> errors;

  const BulkImportResult({
    required this.totalRows,
    required this.importedCount,
    required this.failedCount,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isFullSuccess => failedCount == 0;

  @override
  List<Object?> get props => [totalRows, importedCount, failedCount, errors];
}
