import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockGlobalProductRepository extends Mock
    implements GlobalProductRepository {}

GlobalProduct _buildProduct({
  String id = 'prod-1',
  bool isVerified = false,
}) {
  final now = DateTime(2024, 6, 15);
  return GlobalProduct(
    id: id,
    name: 'Tornillo M6x20',
    sku: 'TORN-M6-20',
    barcode: '7701234567890',
    createdAt: now,
    updatedAt: now,
    isVerified: isVerified,
    verifiedAt: isVerified ? now : null,
  );
}

PaginatedResult<GlobalProduct> _buildPage([int count = 2]) {
  return PaginatedResult<GlobalProduct>(
    items: List.generate(count, (i) => _buildProduct(id: 'prod-$i')),
    totalCount: count,
    page: 1,
    pageSize: 20,
    totalPages: 1,
  );
}

BulkImportResult _buildImportResult({
  int totalRows = 50,
  int importedCount = 50,
  int failedCount = 0,
}) {
  return BulkImportResult(
    totalRows: totalRows,
    importedCount: importedCount,
    failedCount: failedCount,
  );
}

void main() {
  late MockGlobalProductRepository repository;

  setUp(() {
    repository = MockGlobalProductRepository();
    registerFallbackValue(_buildProduct());
    registerFallbackValue(<Map<String, dynamic>>[]);
  });

  // ---------------------------------------------------------------------------
  group('ListGlobalProductsUseCase', () {
    test('delega a repository.listProducts con page y pageSize', () async {
      when(() => repository.listProducts(page: 1, pageSize: 20))
          .thenAnswer((_) async => _buildPage());
      final useCase = ListGlobalProductsUseCase(repository);

      final result = await useCase.execute(1, 20);

      expect(result.items.length, 2);
      verify(() => repository.listProducts(page: 1, pageSize: 20)).called(1);
    });

    test('pasa filtros opcionales al repositorio', () async {
      when(() => repository.listProducts(
            search: 'tornillo',
            businessTypeId: 'bt-ferreteria',
            isVerified: true,
            page: 1,
            pageSize: 10,
          )).thenAnswer((_) async => _buildPage(1));
      final useCase = ListGlobalProductsUseCase(repository);

      await useCase.execute(
        1,
        10,
        search: 'tornillo',
        businessTypeId: 'bt-ferreteria',
        isVerified: true,
      );

      verify(() => repository.listProducts(
            search: 'tornillo',
            businessTypeId: 'bt-ferreteria',
            isVerified: true,
            page: 1,
            pageSize: 10,
          )).called(1);
    });

    test('propaga excepción del repositorio', () async {
      when(() => repository.listProducts(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenThrow(Exception('Network error'));
      final useCase = ListGlobalProductsUseCase(repository);

      expect(() => useCase.execute(1, 20), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  group('GetGlobalProductUseCase', () {
    test('retorna el producto correcto por id', () async {
      final product = _buildProduct(id: 'specific-id');
      when(() => repository.getProduct('specific-id'))
          .thenAnswer((_) async => product);
      final useCase = GetGlobalProductUseCase(repository);

      final result = await useCase.execute('specific-id');

      expect(result.id, 'specific-id');
      verify(() => repository.getProduct('specific-id')).called(1);
    });

    test('propaga not found del repositorio', () async {
      when(() => repository.getProduct('missing'))
          .thenThrow(Exception('Not found'));
      final useCase = GetGlobalProductUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  group('CreateGlobalProductUseCase', () {
    test('crea producto y retorna entidad con id asignado', () async {
      final input = _buildProduct(id: '');
      final created = _buildProduct(id: 'new-id');
      when(() => repository.createProduct(any()))
          .thenAnswer((_) async => created);
      final useCase = CreateGlobalProductUseCase(repository);

      final result = await useCase.execute(input);

      expect(result.id, 'new-id');
      verify(() => repository.createProduct(input)).called(1);
    });

    test('propaga error de conflicto del repositorio', () async {
      when(() => repository.createProduct(any()))
          .thenThrow(Exception('Conflict'));
      final useCase = CreateGlobalProductUseCase(repository);

      expect(() => useCase.execute(_buildProduct()), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  group('UpdateGlobalProductUseCase', () {
    test('actualiza producto y retorna entidad actualizada', () async {
      final updated = _buildProduct(id: 'prod-1');
      when(() => repository.updateProduct(any()))
          .thenAnswer((_) async => updated);
      final useCase = UpdateGlobalProductUseCase(repository);

      final result = await useCase.execute(_buildProduct(id: 'prod-1'));

      expect(result.id, 'prod-1');
      verify(() => repository.updateProduct(any())).called(1);
    });

    test('propaga error del repositorio', () async {
      when(() => repository.updateProduct(any()))
          .thenThrow(Exception('Not found'));
      final useCase = UpdateGlobalProductUseCase(repository);

      expect(() => useCase.execute(_buildProduct()), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  group('DeleteGlobalProductUseCase', () {
    test('elimina producto correctamente', () async {
      when(() => repository.deleteProduct('prod-1'))
          .thenAnswer((_) async {});
      final useCase = DeleteGlobalProductUseCase(repository);

      await useCase.execute('prod-1');

      verify(() => repository.deleteProduct('prod-1')).called(1);
    });

    test('propaga 409 cuando el producto está en uso', () async {
      when(() => repository.deleteProduct(any()))
          .thenThrow(Exception('Product in use by tenants'));
      final useCase = DeleteGlobalProductUseCase(repository);

      expect(() => useCase.execute('prod-in-use'), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  group('VerifyGlobalProductUseCase', () {
    test('llama verifyProduct con el id correcto', () async {
      final verified = _buildProduct(id: 'prod-1', isVerified: true);
      when(() => repository.verifyProduct('prod-1'))
          .thenAnswer((_) async => verified);
      final useCase = VerifyGlobalProductUseCase(repository);

      final result = await useCase.execute('prod-1');

      expect(result.id, 'prod-1');
      expect(result.isVerified, isTrue);
      verify(() => repository.verifyProduct('prod-1')).called(1);
    });

    test('propaga excepción del repositorio', () async {
      when(() => repository.verifyProduct(any()))
          .thenThrow(Exception('Not found'));
      final useCase = VerifyGlobalProductUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  group('UnverifyGlobalProductUseCase', () {
    test('llama unverifyProduct con el id correcto', () async {
      final unverified = _buildProduct(id: 'prod-1', isVerified: false);
      when(() => repository.unverifyProduct('prod-1'))
          .thenAnswer((_) async => unverified);
      final useCase = UnverifyGlobalProductUseCase(repository);

      final result = await useCase.execute('prod-1');

      expect(result.id, 'prod-1');
      expect(result.isVerified, isFalse);
      verify(() => repository.unverifyProduct('prod-1')).called(1);
    });

    test('propaga excepción del repositorio', () async {
      when(() => repository.unverifyProduct(any()))
          .thenThrow(Exception('Not found'));
      final useCase = UnverifyGlobalProductUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  group('BulkImportGlobalProductsUseCase', () {
    test('importa correctamente y retorna resultado con conteos', () async {
      final rows = [
        {'name': 'Tornillo M6', 'sku': 'TORN-M6'},
        {'name': 'Tuerca M6', 'sku': 'TURC-M6'},
      ];
      final importResult = _buildImportResult(
        totalRows: 2,
        importedCount: 2,
        failedCount: 0,
      );
      when(() => repository.bulkImport(rows))
          .thenAnswer((_) async => importResult);
      final useCase = BulkImportGlobalProductsUseCase(repository);

      final result = await useCase.execute(rows);

      expect(result.importedCount, 2);
      expect(result.failedCount, 0);
      expect(result.isFullSuccess, isTrue);
      verify(() => repository.bulkImport(rows)).called(1);
    });

    test('retorna resultado parcial cuando hay filas con error', () async {
      final rows = List.generate(
        52,
        (i) => <String, dynamic>{'name': 'Prod $i', 'sku': 'SKU-$i'},
      );
      final importResult = BulkImportResult(
        totalRows: 52,
        importedCount: 50,
        failedCount: 2,
        errors: const [
          BulkImportError(rowNumber: 5, sku: 'SKU-5', reason: 'SKU duplicado'),
          BulkImportError(rowNumber: 12, reason: 'Nombre vacío'),
        ],
      );
      when(() => repository.bulkImport(any()))
          .thenAnswer((_) async => importResult);
      final useCase = BulkImportGlobalProductsUseCase(repository);

      final result = await useCase.execute(rows);

      expect(result.importedCount, 50);
      expect(result.failedCount, 2);
      expect(result.hasErrors, isTrue);
      expect(result.errors.length, 2);
    });

    test('lista vacía retorna resultado con ceros', () async {
      final emptyResult = _buildImportResult(
        totalRows: 0,
        importedCount: 0,
        failedCount: 0,
      );
      when(() => repository.bulkImport([])).thenAnswer((_) async => emptyResult);
      final useCase = BulkImportGlobalProductsUseCase(repository);

      final result = await useCase.execute([]);

      expect(result.totalRows, 0);
      expect(result.importedCount, 0);
    });

    test('propaga excepción del repositorio', () async {
      when(() => repository.bulkImport(any()))
          .thenThrow(Exception('Payload too large'));
      final useCase = BulkImportGlobalProductsUseCase(repository);

      expect(() => useCase.execute([{'sku': 'x'}]), throwsException);
    });
  });
}
