import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/pim/global_catalog/blocs/global_catalog_bloc.dart';
import 'package:mc_admin/features/pim/global_catalog/blocs/product_form_bloc.dart';
import 'package:mc_admin/features/pim/global_catalog/blocs/bulk_import_bloc.dart';
import 'package:mc_admin/features/pim/global_catalog/global_catalog_screen.dart';
import 'package:mc_admin/features/pim/global_catalog/bulk_import_screen.dart';
import 'package:mc_admin/features/pim/global_catalog/product_detail_screen.dart';

// --- Mocks ---

class MockGlobalCatalogBloc
    extends MockBloc<GlobalCatalogEvent, GlobalCatalogState>
    implements GlobalCatalogBloc {}

class MockProductFormBloc extends MockBloc<ProductFormEvent, ProductFormState>
    implements ProductFormBloc {}

class MockBulkImportBloc extends MockBloc<BulkImportEvent, BulkImportState>
    implements BulkImportBloc {}

// --- Builders ---

GlobalProduct _buildProduct({
  String id = 'prod-1',
  String name = 'Tornillo M6x20',
  String sku = 'TORN-M6-20',
  bool isVerified = false,
}) {
  final now = DateTime(2024, 6, 15);
  return GlobalProduct(
    id: id,
    name: name,
    sku: sku,
    barcode: '7701234567890',
    isVerified: isVerified,
    businessTypeIds: const ['bt-ferreteria'],
    createdAt: now,
    updatedAt: now,
  );
}

GlobalCatalogLoaded _buildLoadedState({int count = 2}) {
  return GlobalCatalogLoaded(
    products: List.generate(
      count,
      (i) => _buildProduct(id: 'prod-$i', name: 'Producto $i', sku: 'SKU-$i'),
    ),
    currentPage: 1,
    pageSize: 20,
    totalItems: count,
  );
}

// --- Helper para construir el widget de pantalla principal ---

Widget _buildGlobalCatalogScreen({
  GlobalCatalogState? catalogState,
  ProductFormState? formState,
}) {
  final catalogBloc = MockGlobalCatalogBloc();
  final formBloc = MockProductFormBloc();

  when(() => catalogBloc.state)
      .thenReturn(catalogState ?? GlobalCatalogInitial());
  when(() => formBloc.state).thenReturn(formState ?? ProductFormInitial());

  return MaterialApp(
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<GlobalCatalogBloc>.value(value: catalogBloc),
          BlocProvider<ProductFormBloc>.value(value: formBloc),
        ],
        child: const GlobalCatalogScreen(),
      ),
    ),
  );
}

// --- Helper para BulkImportScreen ---

Widget _buildBulkImportScreen(BulkImportState state) {
  final bloc = MockBulkImportBloc();
  when(() => bloc.state).thenReturn(state);

  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<BulkImportBloc>.value(
        value: bloc,
        child: const BulkImportScreen(),
      ),
    ),
  );
}

// --- Helper para ProductDetailScreen ---

Widget _buildProductDetailScreen(ProductFormState state) {
  final bloc = MockProductFormBloc();
  when(() => bloc.state).thenReturn(state);

  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<ProductFormBloc>.value(
        value: bloc,
        child: const ProductDetailScreen(productId: 'prod-1'),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(LoadGlobalCatalogEvent());
    registerFallbackValue(RefreshGlobalCatalogEvent());
    registerFallbackValue(ChangeGlobalCatalogPageEvent(1));
    registerFallbackValue(LoadProductEvent(''));
    registerFallbackValue(VerifyProductEvent(''));
    registerFallbackValue(UnverifyProductEvent(''));
    registerFallbackValue(DeleteProductEvent(''));
    registerFallbackValue(ResetBulkImportEvent());
    registerFallbackValue(ParseBulkImportFileEvent(bytes: const [], fileName: ''));
    registerFallbackValue(ConfirmBulkImportEvent(const []));
    registerFallbackValue(
      GlobalProduct(
        id: '',
        name: '',
        sku: '',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    );
    registerFallbackValue(SubmitCreateProductEvent(GlobalProduct(
      id: '',
      name: '',
      sku: '',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    )));
    registerFallbackValue(SubmitUpdateProductEvent(GlobalProduct(
      id: '',
      name: '',
      sku: '',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    )));
  });

  // ============================================================
  // BDD Escenario 1: Lista carga y muestra productos
  // ============================================================

  group('GlobalCatalogScreen — Escenario 1: lista de productos', () {
    testWidgets('muestra CircularProgressIndicator mientras carga',
        (tester) async {
      await tester.pumpWidget(
        _buildGlobalCatalogScreen(catalogState: GlobalCatalogLoading()),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra productos cuando el estado es Loaded', (tester) async {
      await tester.pumpWidget(
        _buildGlobalCatalogScreen(catalogState: _buildLoadedState(count: 2)),
      );
      await tester.pump();

      expect(find.text('Producto 0'), findsOneWidget);
      expect(find.text('Producto 1'), findsOneWidget);
    });

    testWidgets('muestra columnas de la tabla', (tester) async {
      await tester.pumpWidget(
        _buildGlobalCatalogScreen(catalogState: _buildLoadedState()),
      );
      await tester.pump();

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('SKU'), findsOneWidget);
      expect(find.text('Verificado'), findsWidgets);
      expect(find.text('Acciones'), findsOneWidget);
    });

    testWidgets('muestra botón "Nuevo producto"', (tester) async {
      await tester.pumpWidget(
        _buildGlobalCatalogScreen(catalogState: _buildLoadedState()),
      );
      await tester.pump();

      expect(find.text('Nuevo producto'), findsOneWidget);
    });

    testWidgets('muestra botón "Importar" en el FilterBar', (tester) async {
      await tester.pumpWidget(
        _buildGlobalCatalogScreen(catalogState: _buildLoadedState()),
      );
      await tester.pump();

      expect(find.text('Importar'), findsOneWidget);
    });

    testWidgets('muestra filtros de verificación', (tester) async {
      await tester.pumpWidget(
        _buildGlobalCatalogScreen(catalogState: _buildLoadedState()),
      );
      await tester.pump();

      expect(find.text('Todos'), findsOneWidget);
      // "Verificados" puede aparecer en el chip de filtro y en badges de tabla
      expect(find.text('Verificados'), findsWidgets);
      // "Sin verificar" puede aparecer en el chip de filtro y en badges de tabla
      expect(find.text('Sin verificar'), findsWidgets);
    });

    testWidgets('muestra mensaje de error cuando el estado es Error',
        (tester) async {
      await tester.pumpWidget(
        _buildGlobalCatalogScreen(
          catalogState: GlobalCatalogError('Error de red'),
        ),
      );
      await tester.pump();

      expect(find.text('Error de red'), findsOneWidget);
    });

    testWidgets('muestra badges de verificado y sin verificar',
        (tester) async {
      final state = GlobalCatalogLoaded(
        products: [
          _buildProduct(id: 'p1', name: 'Verificado', isVerified: true),
          _buildProduct(id: 'p2', name: 'No verificado', isVerified: false),
        ],
        currentPage: 1,
        pageSize: 20,
        totalItems: 2,
      );

      await tester.pumpWidget(
        _buildGlobalCatalogScreen(catalogState: state),
      );
      await tester.pump();

      // El badge "Verificado" aparece al menos una vez en chips de la tabla
      expect(find.textContaining('Verificado'), findsWidgets);
    });
  });

  // ============================================================
  // BDD Escenario 2: Búsqueda filtra la lista
  // ============================================================

  group('GlobalCatalogScreen — Escenario 2: búsqueda', () {
    testWidgets('muestra campo de búsqueda en la tabla', (tester) async {
      await tester.pumpWidget(
        _buildGlobalCatalogScreen(catalogState: _buildLoadedState()),
      );
      await tester.pump();

      // AdminSearchBar usa TextField internamente
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  // ============================================================
  // BDD Escenario 3: Verificar producto muestra confirmación
  // ============================================================

  group('GlobalCatalogScreen — Escenario 3: verificar producto', () {
    testWidgets(
        'ícono de verificación está presente en acciones de cada fila',
        (tester) async {
      final state = GlobalCatalogLoaded(
        products: [
          _buildProduct(id: 'p1', name: 'Prod 1', isVerified: false),
        ],
        currentPage: 1,
        pageSize: 20,
        totalItems: 1,
      );

      await tester.pumpWidget(
        _buildGlobalCatalogScreen(catalogState: state),
      );
      await tester.pump();

      // Debe haber un ícono de "verificar" (verified_user_outlined)
      expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
    });

    testWidgets(
        'ícono de desverificar aparece para producto ya verificado',
        (tester) async {
      final state = GlobalCatalogLoaded(
        products: [
          _buildProduct(id: 'p1', name: 'Prod 1', isVerified: true),
        ],
        currentPage: 1,
        pageSize: 20,
        totalItems: 1,
      );

      await tester.pumpWidget(
        _buildGlobalCatalogScreen(catalogState: state),
      );
      await tester.pump();

      expect(find.byIcon(Icons.remove_moderator_outlined), findsOneWidget);
    });
  });

  // ============================================================
  // BDD Escenario 4: Eliminar producto bloqueado — error 409
  // ============================================================

  group('GlobalCatalogScreen — Escenario 4: error al eliminar (409)', () {
    testWidgets(
        'muestra ícono de eliminar en acciones de fila', (tester) async {
      final state = GlobalCatalogLoaded(
        products: [_buildProduct()],
        currentPage: 1,
        pageSize: 20,
        totalItems: 1,
      );

      await tester.pumpWidget(
        _buildGlobalCatalogScreen(catalogState: state),
      );
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });

  // ============================================================
  // BDD Escenario 5: Bulk import preview muestra errores
  // ============================================================

  group('BulkImportScreen — Escenario 5: preview con errores highlighted', () {
    testWidgets('muestra vista inicial con área de texto', (tester) async {
      await tester.pumpWidget(
        _buildBulkImportScreen(BulkImportInitial()),
      );
      await tester.pump();

      // Campo de contenido visible
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Previsualizar'), findsOneWidget);
    });

    testWidgets('muestra selector de formato CSV/JSON', (tester) async {
      await tester.pumpWidget(
        _buildBulkImportScreen(BulkImportInitial()),
      );
      await tester.pump();

      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
    });

    testWidgets('muestra CircularProgressIndicator mientras parsea',
        (tester) async {
      await tester.pumpWidget(
        _buildBulkImportScreen(BulkImportParsing()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'preview muestra resumen de válidos y errores', (tester) async {
      final preview = BulkImportPreview(
        rows: const [
          {'name': 'Prod 1', 'sku': 'SKU-1'},
          {'name': '', 'sku': 'SKU-2'},
        ],
        rowErrors: [null, 'Campo "name" requerido'],
      );

      await tester.pumpWidget(
        _buildBulkImportScreen(preview),
      );
      await tester.pump();

      expect(find.text('1 válidos'), findsOneWidget);
      expect(find.text('1 con errores'), findsOneWidget);
    });

    testWidgets('preview con errores muestra ícono de error en fila roja',
        (tester) async {
      final preview = BulkImportPreview(
        rows: const [
          {'name': '', 'sku': 'SKU-1'},
        ],
        rowErrors: ['Campo "name" requerido'],
      );

      await tester.pumpWidget(
        _buildBulkImportScreen(preview),
      );
      await tester.pump();

      // El ícono de error aparece en la fila roja (puede aparecer en resumen también)
      expect(find.byIcon(Icons.error_outline), findsWidgets);
    });

    testWidgets('preview con filas válidas muestra ícono de check verde',
        (tester) async {
      final preview = BulkImportPreview(
        rows: const [
          {'name': 'Prod 1', 'sku': 'SKU-1'},
        ],
        rowErrors: [null],
      );

      await tester.pumpWidget(
        _buildBulkImportScreen(preview),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
    });

    testWidgets(
        '"Confirmar importación" está deshabilitado cuando todas las filas tienen errores',
        (tester) async {
      final preview = BulkImportPreview(
        rows: const [
          {'name': '', 'sku': ''},
        ],
        rowErrors: ['Campo "name" requerido'],
      );

      await tester.pumpWidget(
        _buildBulkImportScreen(preview),
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirmar importación'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
        '"Confirmar importación" está habilitado cuando hay filas válidas',
        (tester) async {
      final preview = BulkImportPreview(
        rows: const [
          {'name': 'Prod 1', 'sku': 'SKU-1'},
        ],
        rowErrors: [null],
      );

      await tester.pumpWidget(
        _buildBulkImportScreen(preview),
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirmar importación'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('resultado exitoso muestra stats de importación',
        (tester) async {
      final successState = BulkImportSuccess(
        const BulkImportResult(
          totalRows: 52,
          importedCount: 50,
          failedCount: 2,
        ),
      );

      await tester.pumpWidget(
        _buildBulkImportScreen(successState),
      );
      await tester.pump();

      expect(find.text('Importación completada'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('muestra botón Descargar template', (tester) async {
      await tester.pumpWidget(
        _buildBulkImportScreen(BulkImportInitial()),
      );
      await tester.pump();

      expect(find.text('Descargar template'), findsOneWidget);
    });
  });

  // ============================================================
  // ProductDetailScreen — tests adicionales
  // ============================================================

  group('ProductDetailScreen', () {
    testWidgets('muestra CircularProgressIndicator mientras carga',
        (tester) async {
      await tester.pumpWidget(
        _buildProductDetailScreen(ProductFormLoading()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra datos del producto cuando está cargado',
        (tester) async {
      final product = _buildProduct(name: 'Tornillo M6x20', sku: 'TORN-M6-20');

      await tester.pumpWidget(
        _buildProductDetailScreen(ProductFormLoaded(product)),
      );
      await tester.pump();

      expect(find.text('Tornillo M6x20'), findsWidgets);
      expect(find.text('TORN-M6-20'), findsOneWidget);
    });

    testWidgets('muestra botón Editar en la AppBar', (tester) async {
      await tester.pumpWidget(
        _buildProductDetailScreen(
          ProductFormLoaded(_buildProduct()),
        ),
      );
      await tester.pump();

      expect(find.text('Editar'), findsOneWidget);
    });

    testWidgets('muestra botón Verificar para producto no verificado',
        (tester) async {
      await tester.pumpWidget(
        _buildProductDetailScreen(
          ProductFormLoaded(_buildProduct(isVerified: false)),
        ),
      );
      await tester.pump();

      expect(find.text('Verificar'), findsOneWidget);
    });

    testWidgets('muestra botón Desverificar para producto verificado',
        (tester) async {
      await tester.pumpWidget(
        _buildProductDetailScreen(
          ProductFormLoaded(_buildProduct(isVerified: true)),
        ),
      );
      await tester.pump();

      expect(find.text('Desverificar'), findsOneWidget);
    });

    testWidgets('muestra mensaje de error cuando falla la carga',
        (tester) async {
      await tester.pumpWidget(
        _buildProductDetailScreen(
          ProductFormError('Error al cargar producto'),
        ),
      );
      await tester.pump();

      expect(find.text('Error al cargar producto'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
