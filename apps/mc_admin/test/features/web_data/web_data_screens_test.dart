import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/web_data/blocs/web_data_dashboard_bloc.dart';
import 'package:mc_admin/features/web_data/blocs/sources_bloc.dart';
import 'package:mc_admin/features/web_data/blocs/source_form_bloc.dart';
import 'package:mc_admin/features/web_data/blocs/jobs_bloc.dart';
import 'package:mc_admin/features/web_data/blocs/web_products_bloc.dart';
import 'package:mc_admin/features/web_data/screens/web_data_dashboard_screen.dart';
import 'package:mc_admin/features/web_data/screens/sources_screen.dart';
import 'package:mc_admin/features/web_data/screens/source_form_screen.dart';
import 'package:mc_admin/features/web_data/screens/jobs_screen.dart';
import 'package:mc_admin/features/web_data/screens/web_products_screen.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockWebDataDashboardBloc
    extends MockBloc<WebDataDashboardEvent, WebDataDashboardState>
    implements WebDataDashboardBloc {}

class MockSourcesBloc extends MockBloc<SourcesEvent, SourcesState>
    implements SourcesBloc {}

class MockSourceFormBloc extends MockBloc<SourceFormEvent, SourceFormState>
    implements SourceFormBloc {}

// T005 mocks
class MockJobsBloc extends MockBloc<JobsEvent, JobsState>
    implements JobsBloc {}

class MockWebProductsBloc
    extends MockBloc<WebProductsEvent, WebProductsState>
    implements WebProductsBloc {}

// ---------------------------------------------------------------------------
// Object Mothers
// ---------------------------------------------------------------------------

WebDataDashboardStats _buildStats({
  int activeSources = 3,
  int inactiveSources = 1,
  int jobsToday = 12,
  int totalProducts = 450,
  double successRate = 0.88,
}) {
  return WebDataDashboardStats(
    activeSources: activeSources,
    inactiveSources: inactiveSources,
    jobsToday: jobsToday,
    totalProducts: totalProducts,
    successRate: successRate,
  );
}

WebJob _buildJob({
  String id = 'job-1',
  String sourceId = 'Fuente MercadoLibre',
  WebJobStatus status = WebJobStatus.completed,
  double progress = 1.0,
  int productsFound = 42,
}) {
  return WebJob(
    id: id,
    sourceId: sourceId,
    status: status,
    progress: progress,
    productsFound: productsFound,
    startedAt: DateTime(2026, 5, 30, 10, 0),
    finishedAt: status != WebJobStatus.running
        ? DateTime(2026, 5, 30, 10, 15)
        : null,
  );
}

WebSource _buildSource({
  String id = 'src-1',
  String name = 'MercadoLibre Ferretería',
  String url = 'https://mercadolibre.com/ferreteria',
  WebSourceStatus status = WebSourceStatus.active,
  String? schedule = '0 * * * *',
  List<String> businessTypeIds = const ['ferreteria'],
}) {
  return WebSource(
    id: id,
    name: name,
    url: url,
    status: status,
    schedule: schedule,
    businessTypeIds: businessTypeIds,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

// ---------------------------------------------------------------------------
// Helpers de construcción de widgets
// ---------------------------------------------------------------------------

Widget _buildDashboardScreen({required WebDataDashboardState state}) {
  final bloc = MockWebDataDashboardBloc();
  when(() => bloc.state).thenReturn(state);

  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<WebDataDashboardBloc>.value(
        value: bloc,
        child: const WebDataDashboardScreen(),
      ),
    ),
  );
}

Widget _buildSourcesScreen({
  required SourcesState state,
  SourceFormState? formState,
}) {
  final sourcesBloc = MockSourcesBloc();
  final formBloc = MockSourceFormBloc();

  when(() => sourcesBloc.state).thenReturn(state);
  when(() => formBloc.state).thenReturn(formState ?? SourceFormInitial());

  return MaterialApp(
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<SourcesBloc>.value(value: sourcesBloc),
          BlocProvider<SourceFormBloc>.value(value: formBloc),
        ],
        child: const SourcesScreen(),
      ),
    ),
  );
}

Widget _buildSourceFormScreen({
  required SourceFormState state,
  String? sourceId,
}) {
  final bloc = MockSourceFormBloc();
  when(() => bloc.state).thenReturn(state);

  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<SourceFormBloc>.value(
        value: bloc,
        child: SourceFormScreen(sourceId: sourceId),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// T005 — Object mother: WebProduct
// ---------------------------------------------------------------------------

WebProduct _buildProduct({
  String id = 'prod-1',
  String sourceId = 'src-1',
  String name = 'Martillo 500g',
  double price = 1250.0,
  String? businessTypeId,
  DateTime? scrapedAt,
}) {
  return WebProduct(
    id: id,
    sourceId: sourceId,
    name: name,
    price: price,
    url: 'https://example.com/prod/$id',
    businessTypeId: businessTypeId,
    scrapedAt: scrapedAt ?? DateTime(2026, 5, 30, 9, 30),
  );
}

WebJob _buildRunningJob({
  String id = 'job-running',
  double progress = 0.45,
}) {
  return WebJob(
    id: id,
    sourceId: 'src-run',
    status: WebJobStatus.running,
    progress: progress,
    productsFound: 20,
    startedAt: DateTime(2026, 5, 30, 10, 0),
    finishedAt: null,
  );
}

WebJob _buildFailedJob({String id = 'job-failed'}) {
  return WebJob(
    id: id,
    sourceId: 'src-fail',
    status: WebJobStatus.failed,
    progress: 0.3,
    productsFound: 5,
    errorLog: 'Connection timeout',
    startedAt: DateTime(2026, 5, 30, 9, 0),
    finishedAt: DateTime(2026, 5, 30, 9, 1),
  );
}

// ---------------------------------------------------------------------------
// T005 — Widget builders
// ---------------------------------------------------------------------------

Widget _buildJobsScreen({required JobsState state}) {
  final bloc = MockJobsBloc();
  when(() => bloc.state).thenReturn(state);

  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<JobsBloc>.value(
        value: bloc,
        child: const JobsScreen(),
      ),
    ),
  );
}

Widget _buildWebProductsScreen({required WebProductsState state}) {
  final bloc = MockWebProductsBloc();
  when(() => bloc.state).thenReturn(state);

  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<WebProductsBloc>.value(
        value: bloc,
        child: const WebProductsScreen(),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(LoadDashboardEvent());
    registerFallbackValue(RefreshDashboardEvent());
    registerFallbackValue(LoadSourcesEvent());
    registerFallbackValue(RefreshSourcesEvent());
    registerFallbackValue(TriggerSourceEvent(''));
    registerFallbackValue(DeleteSourceEvent(''));
    registerFallbackValue(ResetSourceFormEvent());
    registerFallbackValue(LoadSourceEvent(''));
    registerFallbackValue(
      SubmitSourceFormEvent(
        WebSource(
          id: '',
          name: '',
          url: '',
          status: WebSourceStatus.active,
          businessTypeIds: const [],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ),
    );
  });

  // ==========================================================================
  // WebDataDashboardScreen — T004 BDD Escenario 1
  // ==========================================================================

  group('WebDataDashboardScreen — muestra 4 tarjetas de estadísticas', () {
    testWidgets('muestra spinner mientras carga', (tester) async {
      await tester.pumpWidget(
        _buildDashboardScreen(state: WebDataDashboardLoading()),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra las 4 tarjetas cuando el estado es Loaded',
        (tester) async {
      final state = WebDataDashboardLoaded(
        stats: _buildStats(
          activeSources: 3,
          jobsToday: 12,
          totalProducts: 450,
          successRate: 0.88,
        ),
        recentJobs: [],
      );

      await tester.pumpWidget(_buildDashboardScreen(state: state));
      await tester.pump();

      expect(find.text('Fuentes Activas'), findsOneWidget);
      expect(find.text('Jobs Hoy'), findsOneWidget);
      expect(find.text('Productos Totales'), findsOneWidget);
      expect(find.text('Tasa de Éxito'), findsOneWidget);
    });

    testWidgets('tarjeta Fuentes Activas muestra el número correcto',
        (tester) async {
      final state = WebDataDashboardLoaded(
        stats: _buildStats(activeSources: 7),
        recentJobs: [],
      );

      await tester.pumpWidget(_buildDashboardScreen(state: state));
      await tester.pump();

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('tarjeta Tasa de Éxito muestra porcentaje', (tester) async {
      final state = WebDataDashboardLoaded(
        stats: _buildStats(successRate: 0.92),
        recentJobs: [],
      );

      await tester.pumpWidget(_buildDashboardScreen(state: state));
      await tester.pump();

      expect(find.text('92%'), findsOneWidget);
    });

    testWidgets('muestra lista de jobs recientes', (tester) async {
      final jobs = [
        _buildJob(
          id: 'job-1',
          sourceId: 'src-ml',
          status: WebJobStatus.completed,
        ),
        _buildJob(
          id: 'job-2',
          sourceId: 'src-uf',
          status: WebJobStatus.running,
        ),
      ];
      final state = WebDataDashboardLoaded(
        stats: _buildStats(),
        recentJobs: jobs,
      );

      await tester.pumpWidget(_buildDashboardScreen(state: state));
      await tester.pump();

      expect(find.text('Jobs recientes'), findsOneWidget);
      expect(find.text('src-ml'), findsOneWidget);
      expect(find.text('src-uf'), findsOneWidget);
    });

    testWidgets('muestra badge de estado del job en la lista', (tester) async {
      final state = WebDataDashboardLoaded(
        stats: _buildStats(),
        recentJobs: [
          _buildJob(status: WebJobStatus.failed),
        ],
      );

      await tester.pumpWidget(_buildDashboardScreen(state: state));
      await tester.pumpAndSettle();

      // StatusBadge.fromString(status.name) usa el nombre como customLabel.
      // El badge muestra el valor crudo del enum ('failed').
      expect(find.text('failed'), findsOneWidget);
    });

    testWidgets('muestra mensaje cuando no hay jobs recientes', (tester) async {
      final state = WebDataDashboardLoaded(
        stats: _buildStats(),
        recentJobs: [],
      );

      await tester.pumpWidget(_buildDashboardScreen(state: state));
      await tester.pump();

      expect(find.text('No hay jobs recientes'), findsOneWidget);
    });

    testWidgets('muestra error cuando el estado es Error', (tester) async {
      await tester.pumpWidget(
        _buildDashboardScreen(
          state: WebDataDashboardError('Error de conexión'),
        ),
      );
      await tester.pump();

      expect(find.text('Error de conexión'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  // ==========================================================================
  // SourcesScreen — T004 BDD Escenario 2
  // ==========================================================================

  group('SourcesScreen — lista con filtros y acciones', () {
    testWidgets('muestra spinner mientras carga', (tester) async {
      await tester.pumpWidget(
        _buildSourcesScreen(state: SourcesLoading()),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra chips de filtro de estado', (tester) async {
      await tester.pumpWidget(
        _buildSourcesScreen(state: SourcesLoaded(sources: [])),
      );
      await tester.pump();

      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('Inactivo'), findsOneWidget);
      expect(find.text('Corriendo'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('muestra botón "Nueva fuente"', (tester) async {
      await tester.pumpWidget(
        _buildSourcesScreen(state: SourcesLoaded(sources: [])),
      );
      await tester.pump();

      expect(find.text('Nueva fuente'), findsOneWidget);
    });

    testWidgets('muestra columnas correctas en la tabla', (tester) async {
      final state = SourcesLoaded(sources: [_buildSource()]);

      await tester.pumpWidget(_buildSourcesScreen(state: state));
      await tester.pump();

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('URL'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Tipos negocio'), findsOneWidget);
      expect(find.text('Acciones'), findsOneWidget);
    });

    testWidgets('muestra nombre de la fuente en la tabla', (tester) async {
      final state = SourcesLoaded(
        sources: [_buildSource(name: 'MercadoLibre Ferretería')],
      );

      await tester.pumpWidget(_buildSourcesScreen(state: state));
      await tester.pump();

      expect(find.text('MercadoLibre Ferretería'), findsOneWidget);
    });

    testWidgets('botón trigger está deshabilitado para fuente running',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = SourcesLoaded(
        sources: [_buildSource(status: WebSourceStatus.running)],
      );

      await tester.pumpWidget(_buildSourcesScreen(state: state));
      await tester.pump();

      // El IconButton de play_circle_outline debe estar deshabilitado
      final playIcon = find.byIcon(Icons.play_circle_outline);
      expect(playIcon, findsOneWidget);

      final iconButton = tester.widget<IconButton>(
        find.ancestor(of: playIcon, matching: find.byType(IconButton)).first,
      );
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('botón trigger está habilitado para fuente activa',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = SourcesLoaded(
        sources: [_buildSource(status: WebSourceStatus.active)],
      );

      await tester.pumpWidget(_buildSourcesScreen(state: state));
      await tester.pump();

      final playIcon = find.byIcon(Icons.play_circle_outline);
      expect(playIcon, findsOneWidget);

      final iconButton = tester.widget<IconButton>(
        find.ancestor(of: playIcon, matching: find.byType(IconButton)).first,
      );
      expect(iconButton.onPressed, isNotNull);
    });

    testWidgets('tap en eliminar muestra ConfirmDialog', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = SourcesLoaded(
        sources: [_buildSource(name: 'ML Ferretería')],
      );

      await tester.pumpWidget(_buildSourcesScreen(state: state));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar fuente'), findsOneWidget);
      expect(find.text('Eliminar'), findsWidgets);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('muestra badge de estado de la fuente', (tester) async {
      final state = SourcesLoaded(
        sources: [_buildSource(status: WebSourceStatus.active)],
      );

      await tester.pumpWidget(_buildSourcesScreen(state: state));
      await tester.pump();

      // StatusBadge.fromString('active') → 'Activo'
      expect(find.text('Activo'), findsOneWidget);
    });

    testWidgets('muestra schedule de la fuente', (tester) async {
      final state = SourcesLoaded(
        sources: [_buildSource(schedule: '0 2 * * *')],
      );

      await tester.pumpWidget(_buildSourcesScreen(state: state));
      await tester.pump();

      expect(find.text('0 2 * * *'), findsOneWidget);
    });

    testWidgets('muestra "—" cuando la fuente no tiene schedule', (tester) async {
      final state = SourcesLoaded(
        sources: [_buildSource(schedule: null)],
      );

      await tester.pumpWidget(_buildSourcesScreen(state: state));
      await tester.pump();

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('muestra mensaje de error cuando falla la carga', (tester) async {
      await tester.pumpWidget(
        _buildSourcesScreen(
          state: SourcesError('Error al cargar fuentes'),
        ),
      );
      await tester.pump();

      expect(find.text('Error al cargar fuentes'), findsOneWidget);
    });
  });

  // ==========================================================================
  // SourceFormScreen — T004 BDD Escenario 2 (formulario)
  // ==========================================================================

  group('SourceFormScreen — creación y edición', () {
    testWidgets('muestra título "Nueva Fuente" en modo creación', (tester) async {
      await tester.pumpWidget(
        _buildSourceFormScreen(state: SourceFormInitial()),
      );
      await tester.pump();

      expect(find.text('Nueva Fuente'), findsOneWidget);
    });

    testWidgets('muestra título "Editar Fuente" en modo edición', (tester) async {
      await tester.pumpWidget(
        _buildSourceFormScreen(
          state: SourceFormInitial(),
          sourceId: 'src-1',
        ),
      );
      await tester.pump();

      expect(find.text('Editar Fuente'), findsOneWidget);
    });

    testWidgets('muestra campos obligatorios Nombre y URL', (tester) async {
      await tester.pumpWidget(
        _buildSourceFormScreen(state: SourceFormInitial()),
      );
      await tester.pump();

      expect(find.text('Nombre *'), findsOneWidget);
      expect(find.text('URL *'), findsOneWidget);
    });

    testWidgets('muestra campo Schedule con hint cron', (tester) async {
      await tester.pumpWidget(
        _buildSourceFormScreen(state: SourceFormInitial()),
      );
      await tester.pump();

      expect(find.text('Schedule (cron)'), findsOneWidget);
    });

    testWidgets('muestra dropdown de Estado', (tester) async {
      await tester.pumpWidget(
        _buildSourceFormScreen(state: SourceFormInitial()),
      );
      await tester.pump();

      expect(find.text('Estado'), findsOneWidget);
    });

    testWidgets('muestra sección de Tipos de negocio', (tester) async {
      await tester.pumpWidget(
        _buildSourceFormScreen(state: SourceFormInitial()),
      );
      await tester.pump();

      expect(find.text('Tipos de negocio'), findsOneWidget);
    });

    testWidgets('validación falla cuando el nombre está vacío', (tester) async {
      await tester.pumpWidget(
        _buildSourceFormScreen(state: SourceFormInitial()),
      );
      await tester.pump();

      // Tap en el botón Guardar del footer (último en el árbol)
      await tester.tap(find.text('Guardar').last);
      await tester.pump();

      expect(find.text('El nombre es obligatorio'), findsOneWidget);
    });

    testWidgets('validación falla cuando la URL es inválida', (tester) async {
      await tester.pumpWidget(
        _buildSourceFormScreen(state: SourceFormInitial()),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre *'),
        'Mi fuente',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'URL *'),
        'no-es-una-url',
      );
      await tester.tap(find.text('Guardar').last);
      await tester.pump();

      expect(find.textContaining('URL válida'), findsOneWidget);
    });

    testWidgets('muestra botones Guardar y Cancelar', (tester) async {
      await tester.pumpWidget(
        _buildSourceFormScreen(state: SourceFormInitial()),
      );
      await tester.pump();

      expect(find.text('Guardar'), findsWidgets); // AppBar + footer
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('muestra spinner cuando el estado es Loading', (tester) async {
      await tester.pumpWidget(
        _buildSourceFormScreen(state: SourceFormLoading()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
