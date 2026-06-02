import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

BulkImportError buildError({
  int rowNumber = 1,
  String? sku = 'SKU-ERR',
  String reason = 'SKU duplicado',
}) {
  return BulkImportError(rowNumber: rowNumber, sku: sku, reason: reason);
}

BulkImportResult buildResult({
  int totalRows = 10,
  int importedCount = 8,
  int failedCount = 2,
  List<BulkImportError> errors = const [],
}) {
  return BulkImportResult(
    totalRows: totalRows,
    importedCount: importedCount,
    failedCount: failedCount,
    errors: errors,
  );
}

void main() {
  group('BulkImportError', () {
    test('construye con campos obligatorios', () {
      final error = buildError();
      expect(error.rowNumber, 1);
      expect(error.sku, 'SKU-ERR');
      expect(error.reason, 'SKU duplicado');
    });

    test('sku es null por defecto cuando no se provee', () {
      const error = BulkImportError(rowNumber: 5, reason: 'Falta nombre');
      expect(error.sku, isNull);
      expect(error.rowNumber, 5);
      expect(error.reason, 'Falta nombre');
    });

    test('igualdad por valor (Equatable)', () {
      final e1 = buildError();
      final e2 = buildError();
      expect(e1, equals(e2));
    });

    test('distintos rowNumber generan errores distintos', () {
      final e1 = buildError(rowNumber: 1);
      final e2 = buildError(rowNumber: 2);
      expect(e1, isNot(equals(e2)));
    });

    test('distintos reason generan errores distintos', () {
      final e1 = buildError(reason: 'SKU duplicado');
      final e2 = buildError(reason: 'Nombre vacío');
      expect(e1, isNot(equals(e2)));
    });
  });

  group('BulkImportResult', () {
    test('construye con campos obligatorios', () {
      final result = buildResult();
      expect(result.totalRows, 10);
      expect(result.importedCount, 8);
      expect(result.failedCount, 2);
      expect(result.errors, isEmpty);
    });

    test('errors vacío por defecto', () {
      final result = BulkImportResult(
        totalRows: 5,
        importedCount: 5,
        failedCount: 0,
      );
      expect(result.errors, isEmpty);
    });

    test('hasErrors retorna false cuando no hay errores', () {
      final result = buildResult(failedCount: 0, errors: []);
      expect(result.hasErrors, isFalse);
    });

    test('hasErrors retorna true cuando hay errores en la lista', () {
      final result = buildResult(errors: [buildError()]);
      expect(result.hasErrors, isTrue);
    });

    test('isFullSuccess retorna true cuando failedCount es 0', () {
      final result = buildResult(failedCount: 0, errors: []);
      expect(result.isFullSuccess, isTrue);
    });

    test('isFullSuccess retorna false cuando hay fallos', () {
      final result = buildResult(failedCount: 2);
      expect(result.isFullSuccess, isFalse);
    });

    test('igualdad por valor (Equatable)', () {
      final r1 = buildResult();
      final r2 = buildResult();
      expect(r1, equals(r2));
    });

    test('distintos importedCount generan resultados distintos', () {
      final r1 = buildResult(importedCount: 8);
      final r2 = buildResult(importedCount: 9);
      expect(r1, isNot(equals(r2)));
    });

    test('construye con lista de errores', () {
      final errors = [
        buildError(rowNumber: 3, sku: 'ERR-03', reason: 'SKU duplicado'),
        buildError(rowNumber: 7, sku: null, reason: 'Nombre vacío'),
      ];
      final result = BulkImportResult(
        totalRows: 10,
        importedCount: 8,
        failedCount: 2,
        errors: errors,
      );
      expect(result.errors.length, 2);
      expect(result.errors[0].rowNumber, 3);
      expect(result.errors[1].sku, isNull);
      expect(result.hasErrors, isTrue);
      expect(result.isFullSuccess, isFalse);
    });

    test('resultado con éxito total y lista de errores vacía', () {
      final result = BulkImportResult(
        totalRows: 50,
        importedCount: 50,
        failedCount: 0,
        errors: const [],
      );
      expect(result.isFullSuccess, isTrue);
      expect(result.hasErrors, isFalse);
    });
  });
}
