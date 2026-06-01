import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/pim/global_catalog/blocs/global_catalog_bloc.dart';
import 'package:mc_admin/features/pim/global_catalog/blocs/product_form_bloc.dart';
import 'package:mc_admin/features/pim/global_catalog/blocs/bulk_import_bloc.dart';

// --- Mocks ---

class MockListGlobalProductsUseCase extends Mock
    implements ListGlobalProductsUseCase {}

class MockGetGlobalProductUseCase extends Mock
    implements GetGlobalProductUseCase {}

class MockCreateGlobalProductUseCase extends Mock
    implements CreateGlobalProductUseCase {}

class MockUpdateGlobalProductUseCase extends Mock
    implements UpdateGlobalProductUseCase {}

class MockDeleteGlobalProductUseCase extends Mock
    implements DeleteGlobalProductUseCase {}

class MockVerifyGlobalProductUseCase extends Mock
    implements VerifyGlobalProductUseCase {}

class MockUnverifyGlobalProductUseCase extends Mock
    implements UnverifyGlobalProductUseCase {}

class MockBulkImportGlobalProductsUseCase extends Mock
    implements BulkImportGlobalProductsUseCase {}

// --- Builders ---

GlobalProduct _buildProduct({String id = 'prod-1', bool isVerified = false}) {
  final now = DateTime(2024, 6, 15);
  return GlobalProduct(
    id: id,
    name: 'Tornillo M6x20',
    sku: 'TORN-M6-20',
    isVerified: isVerified,
    createdAt: now,
    updatedAt: now,
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
  int imported = 5,
  int failed = 0,
}) {
  return BulkImportResult(
    totalRows: imported + failed,
    importedCount: imported,
    failedCount: failed,
  );
}

void main() {
  // --- GlobalCatalogBloc ---

  group('GlobalCatalogBloc', () {
    late MockListGlobalProductsUseCase listUseCase;

    setUp(() {
      listUseCase = MockListGlobalProductsUseCase();
    });

    GlobalCatalogBloc buildBloc() =>
        GlobalCatalogBloc(list: listUseCase);

    blocTest<GlobalCatalogBloc, GlobalCatalogState>(
      'emite [Loading, Loaded] al cargar exitosamente',
      build: () {
        when(() => listUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage());
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadGlobalCatalogEvent()),
      expect: () => [
        isA<GlobalCatalogLoading>(),
        isA<GlobalCatalogLoaded>(),
      ],
    );

    blocTest<GlobalCatalogBloc, GlobalCatalogState>(
      'emite [Loading, Error] cuando el use case falla',
      build: () {
        when(() => listUseCase.execute(1, 20))
            .thenThrow(Exception('Network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadGlobalCatalogEvent()),
      expect: () => [
        isA<GlobalCatalogLoading>(),
        isA<GlobalCatalogError>(),
      ],
    );

    blocTest<GlobalCatalogBloc, GlobalCatalogState>(
      'GlobalCatalogLoaded contiene los productos correctos',
      build: () {
        when(() => listUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage(3));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadGlobalCatalogEvent()),
      expect: () => [
        isA<GlobalCatalogLoading>(),
        isA<GlobalCatalogLoaded>()
            .having((s) => s.products.length, 'products count', 3),
      ],
    );

    blocTest<GlobalCatalogBloc, GlobalCatalogState>(
      'pasa filtros search, businessTypeId e isVerified al use case',
      build: () {
        when(() => listUseCase.execute(
              1,
              20,
              search: 'tornillo',
              businessTypeId: 'bt-1',
              isVerified: true,
            )).thenAnswer((_) async => _buildPage(1));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadGlobalCatalogEvent(
        search: 'tornillo',
        businessTypeId: 'bt-1',
        isVerified: true,
      )),
      verify: (_) {
        verify(() => listUseCase.execute(
              1,
              20,
              search: 'tornillo',
              businessTypeId: 'bt-1',
              isVerified: true,
            )).called(1);
      },
    );

    blocTest<GlobalCatalogBloc, GlobalCatalogState>(
      'ChangeGlobalCatalogPageEvent carga la página correcta',
      build: () {
        when(() => listUseCase.execute(any(), any()))
            .thenAnswer((_) async => _buildPage());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadGlobalCatalogEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(ChangeGlobalCatalogPageEvent(2));
      },
      skip: 2,
      expect: () => [
        isA<GlobalCatalogLoading>(),
        isA<GlobalCatalogLoaded>(),
      ],
    );

    blocTest<GlobalCatalogBloc, GlobalCatalogState>(
      'RefreshGlobalCatalogEvent recarga con los mismos filtros',
      build: () {
        when(() => listUseCase.execute(1, 20, search: 'tornillo'))
            .thenAnswer((_) async => _buildPage(1));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadGlobalCatalogEvent(search: 'tornillo'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(RefreshGlobalCatalogEvent());
      },
      skip: 2,
      verify: (_) {
        verify(() => listUseCase.execute(1, 20, search: 'tornillo')).called(2);
      },
    );

    test('GlobalCatalogLoaded.totalPages calcula correctamente', () {
      final state = GlobalCatalogLoaded(
        products: const [],
        currentPage: 1,
        pageSize: 10,
        totalItems: 25,
      );
      expect(state.totalPages, 3);
    });

    test('GlobalCatalogLoaded.totalPages con pageSize 0 retorna 1', () {
      final state = GlobalCatalogLoaded(
        products: const [],
        currentPage: 1,
        pageSize: 0,
        totalItems: 10,
      );
      expect(state.totalPages, 1);
    });

    test('GlobalCatalogError guarda el mensaje', () {
      final state = GlobalCatalogError('Error de red');
      expect(state.message, 'Error de red');
    });
  });

  // --- ProductFormBloc ---

  group('ProductFormBloc', () {
    late MockGetGlobalProductUseCase getUseCase;
    late MockCreateGlobalProductUseCase createUseCase;
    late MockUpdateGlobalProductUseCase updateUseCase;
    late MockDeleteGlobalProductUseCase deleteUseCase;
    late MockVerifyGlobalProductUseCase verifyUseCase;
    late MockUnverifyGlobalProductUseCase unverifyUseCase;

    setUp(() {
      getUseCase = MockGetGlobalProductUseCase();
      createUseCase = MockCreateGlobalProductUseCase();
      updateUseCase = MockUpdateGlobalProductUseCase();
      deleteUseCase = MockDeleteGlobalProductUseCase();
      verifyUseCase = MockVerifyGlobalProductUseCase();
      unverifyUseCase = MockUnverifyGlobalProductUseCase();
      registerFallbackValue(_buildProduct());
    });

    ProductFormBloc buildBloc() => ProductFormBloc(
          get: getUseCase,
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
          verify: verifyUseCase,
          unverify: unverifyUseCase,
        );

    blocTest<ProductFormBloc, ProductFormState>(
      'LoadProductEvent emite [Loading, Loaded] al cargar exitosamente',
      build: () {
        when(() => getUseCase.execute('prod-1'))
            .thenAnswer((_) async => _buildProduct());
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadProductEvent('prod-1')),
      expect: () => [
        isA<ProductFormLoading>(),
        isA<ProductFormLoaded>(),
      ],
    );

    blocTest<ProductFormBloc, ProductFormState>(
      'LoadProductEvent emite [Loading, Error] cuando falla',
      build: () {
        when(() => getUseCase.execute(any())).thenThrow(Exception('Not found'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadProductEvent('missing')),
      expect: () => [
        isA<ProductFormLoading>(),
        isA<ProductFormError>(),
      ],
    );

    blocTest<ProductFormBloc, ProductFormState>(
      'SubmitCreateProductEvent emite [Submitting, Success] al crear exitosamente',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenAnswer((_) async => _buildProduct());
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(SubmitCreateProductEvent(_buildProduct(id: 'new-prod'))),
      expect: () => [
        isA<ProductFormSubmitting>(),
        isA<ProductFormSuccess>(),
      ],
    );

    blocTest<ProductFormBloc, ProductFormState>(
      'SubmitCreateProductEvent emite [Submitting, Error] cuando falla',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenThrow(Exception('Server error'));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(SubmitCreateProductEvent(_buildProduct(id: 'new-prod'))),
      expect: () => [
        isA<ProductFormSubmitting>(),
        isA<ProductFormError>(),
      ],
    );

    blocTest<ProductFormBloc, ProductFormState>(
      'SubmitUpdateProductEvent emite [Submitting, Success] al actualizar',
      build: () {
        when(() => updateUseCase.execute(any()))
            .thenAnswer((_) async => _buildProduct());
        return buildBloc();
      },
      act: (bloc) => bloc.add(SubmitUpdateProductEvent(_buildProduct())),
      expect: () => [
        isA<ProductFormSubmitting>(),
        isA<ProductFormSuccess>(),
      ],
    );

    blocTest<ProductFormBloc, ProductFormState>(
      'DeleteProductEvent emite [Submitting, Deleted] al eliminar exitosamente',
      build: () {
        when(() => deleteUseCase.execute(any())).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(DeleteProductEvent('prod-1')),
      expect: () => [
        isA<ProductFormSubmitting>(),
        isA<ProductFormDeleted>(),
      ],
    );

    blocTest<ProductFormBloc, ProductFormState>(
      'DeleteProductEvent emite [Submitting, Error] cuando falla',
      build: () {
        when(() => deleteUseCase.execute(any()))
            .thenThrow(Exception('Forbidden'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(DeleteProductEvent('prod-1')),
      expect: () => [
        isA<ProductFormSubmitting>(),
        isA<ProductFormError>(),
      ],
    );

    blocTest<ProductFormBloc, ProductFormState>(
      'VerifyProductEvent emite [Submitting, Success] al verificar',
      build: () {
        when(() => verifyUseCase.execute('prod-1'))
            .thenAnswer((_) async => _buildProduct(isVerified: true));
        return buildBloc();
      },
      act: (bloc) => bloc.add(VerifyProductEvent('prod-1')),
      expect: () => [
        isA<ProductFormSubmitting>(),
        isA<ProductFormSuccess>().having(
          (s) => s.product?.isVerified,
          'isVerified',
          isTrue,
        ),
      ],
    );

    blocTest<ProductFormBloc, ProductFormState>(
      'UnverifyProductEvent emite [Submitting, Success] al desverificar',
      build: () {
        when(() => unverifyUseCase.execute('prod-1'))
            .thenAnswer((_) async => _buildProduct(isVerified: false));
        return buildBloc();
      },
      act: (bloc) => bloc.add(UnverifyProductEvent('prod-1')),
      expect: () => [
        isA<ProductFormSubmitting>(),
        isA<ProductFormSuccess>(),
      ],
    );

    blocTest<ProductFormBloc, ProductFormState>(
      'VerifyProductEvent emite [Submitting, Error] cuando falla',
      build: () {
        when(() => verifyUseCase.execute(any()))
            .thenThrow(Exception('Not found'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(VerifyProductEvent('missing')),
      expect: () => [
        isA<ProductFormSubmitting>(),
        isA<ProductFormError>(),
      ],
    );

    blocTest<ProductFormBloc, ProductFormState>(
      'ResetProductFormEvent regresa a ProductFormInitial',
      build: () => buildBloc(),
      seed: () => ProductFormError('prev error'),
      act: (bloc) => bloc.add(ResetProductFormEvent()),
      expect: () => [isA<ProductFormInitial>()],
    );
  });

  // --- BulkImportBloc ---

  group('BulkImportBloc', () {
    late MockBulkImportGlobalProductsUseCase bulkImportUseCase;

    setUp(() {
      bulkImportUseCase = MockBulkImportGlobalProductsUseCase();
      registerFallbackValue(<Map<String, dynamic>>[]);
    });

    BulkImportBloc buildBloc() =>
        BulkImportBloc(bulkImport: bulkImportUseCase);

    blocTest<BulkImportBloc, BulkImportState>(
      'ParseBulkImportFileEvent con JSON válido emite [Parsing, Preview]',
      build: () => buildBloc(),
      act: (bloc) {
        const json = '[{"name":"Prod1","sku":"SKU1"},{"name":"Prod2","sku":"SKU2"}]';
        bloc.add(ParseBulkImportFileEvent(
          bytes: json.codeUnits,
          fileName: 'products.json',
        ));
      },
      expect: () => [
        isA<BulkImportParsing>(),
        isA<BulkImportPreview>().having(
          (s) => s.rows.length,
          'rows count',
          2,
        ),
      ],
    );

    blocTest<BulkImportBloc, BulkImportState>(
      'ParseBulkImportFileEvent con CSV válido emite [Parsing, Preview]',
      build: () => buildBloc(),
      act: (bloc) {
        const csv = 'name,sku\nTornillo M6,TORN-M6\nTuerca M6,TU-M6';
        bloc.add(ParseBulkImportFileEvent(
          bytes: csv.codeUnits,
          fileName: 'products.csv',
        ));
      },
      expect: () => [
        isA<BulkImportParsing>(),
        isA<BulkImportPreview>().having(
          (s) => s.rows.length,
          'rows count',
          2,
        ),
      ],
    );

    blocTest<BulkImportBloc, BulkImportState>(
      'BulkImportPreview detecta filas con errores de validación',
      build: () => buildBloc(),
      act: (bloc) {
        // Fila 1 válida, fila 2 sin name, fila 3 sin sku
        const csv = 'name,sku\nTornillo M6,TORN-M6\n,TU-M6\nTuerca M8,';
        bloc.add(ParseBulkImportFileEvent(
          bytes: csv.codeUnits,
          fileName: 'products.csv',
        ));
      },
      expect: () => [
        isA<BulkImportParsing>(),
        isA<BulkImportPreview>()
            .having((s) => s.validRowCount, 'validRowCount', 1)
            .having((s) => s.errorRowCount, 'errorRowCount', 2),
      ],
    );

    blocTest<BulkImportBloc, BulkImportState>(
      'ConfirmBulkImportEvent emite [Uploading, Success] al importar exitosamente',
      build: () {
        when(() => bulkImportUseCase.execute(any()))
            .thenAnswer((_) async => _buildImportResult(imported: 5));
        return buildBloc();
      },
      act: (bloc) => bloc.add(ConfirmBulkImportEvent(
        List.generate(5, (i) => {'name': 'Prod $i', 'sku': 'SKU-$i'}),
      )),
      expect: () => [
        isA<BulkImportUploading>(),
        isA<BulkImportSuccess>().having(
          (s) => s.result.importedCount,
          'importedCount',
          5,
        ),
      ],
    );

    blocTest<BulkImportBloc, BulkImportState>(
      'ConfirmBulkImportEvent emite [Uploading, Error] cuando falla',
      build: () {
        when(() => bulkImportUseCase.execute(any()))
            .thenThrow(Exception('Server error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(ConfirmBulkImportEvent(const [
        {'name': 'Prod1', 'sku': 'SKU-1'},
      ])),
      expect: () => [
        isA<BulkImportUploading>(),
        isA<BulkImportFailed>(),
      ],
    );

    blocTest<BulkImportBloc, BulkImportState>(
      'ResetBulkImportEvent regresa a BulkImportInitial',
      build: () => buildBloc(),
      seed: () => BulkImportFailed('prev error'),
      act: (bloc) => bloc.add(ResetBulkImportEvent()),
      expect: () => [isA<BulkImportInitial>()],
    );

    blocTest<BulkImportBloc, BulkImportState>(
      'CSV sin datos emite Preview con rows vacías',
      build: () => buildBloc(),
      act: (bloc) {
        const csv = 'name,sku\n';
        bloc.add(ParseBulkImportFileEvent(
          bytes: csv.codeUnits,
          fileName: 'empty.csv',
        ));
      },
      expect: () => [
        isA<BulkImportParsing>(),
        isA<BulkImportPreview>().having((s) => s.rows.length, 'rows', 0),
      ],
    );
  });
}
