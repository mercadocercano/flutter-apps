import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class BulkImportEvent {}

class ParseBulkImportFileEvent extends BulkImportEvent {
  final List<int> bytes;
  final String fileName;

  ParseBulkImportFileEvent({required this.bytes, required this.fileName});
}

class ConfirmBulkImportEvent extends BulkImportEvent {
  final List<Map<String, dynamic>> rows;
  ConfirmBulkImportEvent(this.rows);
}

class ResetBulkImportEvent extends BulkImportEvent {}

// --- States ---

abstract class BulkImportState {}

class BulkImportInitial extends BulkImportState {}

class BulkImportParsing extends BulkImportState {}

class BulkImportPreview extends BulkImportState {
  /// Filas parseadas del archivo. Cada fila es un mapa con los campos del producto.
  final List<Map<String, dynamic>> rows;

  /// Errores de validación encontrados durante el parseo (índice 0 = fila 1).
  final List<String?> rowErrors;

  BulkImportPreview({required this.rows, required this.rowErrors});

  int get validRowCount => rowErrors.where((e) => e == null).length;
  int get errorRowCount => rowErrors.where((e) => e != null).length;
}

class BulkImportUploading extends BulkImportState {}

class BulkImportSuccess extends BulkImportState {
  final BulkImportResult result;
  BulkImportSuccess(this.result);
}

class BulkImportFailed extends BulkImportState {
  final String message;
  BulkImportFailed(this.message);
}

// --- Bloc ---

class BulkImportBloc extends Bloc<BulkImportEvent, BulkImportState> {
  final BulkImportGlobalProductsUseCase _bulkImport;

  BulkImportBloc({required BulkImportGlobalProductsUseCase bulkImport})
      : _bulkImport = bulkImport,
        super(BulkImportInitial()) {
    on<ParseBulkImportFileEvent>(_onParse);
    on<ConfirmBulkImportEvent>(_onConfirm);
    on<ResetBulkImportEvent>(_onReset);
  }

  Future<void> _onParse(
    ParseBulkImportFileEvent event,
    Emitter<BulkImportState> emit,
  ) async {
    emit(BulkImportParsing());
    try {
      final preview = _parseFile(event.bytes, event.fileName);
      emit(preview);
    } catch (e) {
      emit(BulkImportFailed('Error al parsear archivo: $e'));
    }
  }

  Future<void> _onConfirm(
    ConfirmBulkImportEvent event,
    Emitter<BulkImportState> emit,
  ) async {
    emit(BulkImportUploading());
    try {
      final result = await _bulkImport.execute(event.rows);
      emit(BulkImportSuccess(result));
    } catch (e) {
      emit(BulkImportFailed('Error al importar productos: $e'));
    }
  }

  void _onReset(
    ResetBulkImportEvent event,
    Emitter<BulkImportState> emit,
  ) {
    emit(BulkImportInitial());
  }

  /// Parsea el archivo CSV o JSON en memoria y genera el preview.
  BulkImportPreview _parseFile(List<int> bytes, String fileName) {
    final extension = fileName.toLowerCase().split('.').last;

    if (extension == 'json') {
      return _parseJson(bytes);
    }

    // Tratar como CSV por defecto
    return _parseCsv(bytes);
  }

  BulkImportPreview _parseJson(List<int> bytes) {
    final content = utf8.decode(bytes);
    final decoded = jsonDecode(content);

    final rawList = decoded is List
        ? decoded
        : (decoded as Map<String, dynamic>)['products'] as List? ?? [];

    final rows = rawList.cast<Map<String, dynamic>>();
    final errors = rows.map(_validateRow).toList();

    return BulkImportPreview(rows: rows, rowErrors: errors);
  }

  BulkImportPreview _parseCsv(List<int> bytes) {
    final content = utf8.decode(bytes);
    final lines = content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return BulkImportPreview(rows: const [], rowErrors: const []);
    }

    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    final dataLines = lines.skip(1).toList();

    final rows = <Map<String, dynamic>>[];
    final errors = <String?>[];

    for (final line in dataLines) {
      final values = line.split(',').map((v) => v.trim()).toList();
      final row = <String, dynamic>{};

      for (var i = 0; i < headers.length; i++) {
        row[headers[i]] = i < values.length ? values[i] : '';
      }

      rows.add(row);
      errors.add(_validateRow(row));
    }

    return BulkImportPreview(rows: rows, rowErrors: errors);
  }

  /// Valida una fila. Retorna null si es válida, o el mensaje de error.
  String? _validateRow(Map<String, dynamic> row) {
    final name = row['name'] as String?;
    final sku = row['sku'] as String?;

    if (name == null || name.isEmpty) return 'Campo "name" requerido';
    if (sku == null || sku.isEmpty) return 'Campo "sku" requerido';

    return null;
  }
}
