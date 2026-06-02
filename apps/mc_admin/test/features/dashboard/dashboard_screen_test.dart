import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/dashboard/dashboard_screen.dart';
import 'package:mc_admin/features/dashboard/blocs/dashboard_bloc.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

IamStats _iam() => const IamStats(
      activeTenants: 42,
      newTenantsLast24h: 2,
      totalRoles: 5,
      totalPlans: 3,
    );

PimStats _pim() => const PimStats(
      totalCategories: 100,
      verifiedBrands: 50,
      totalBrands: 70,
      verifiedProducts: 2000,
      totalProducts: 3000,
      totalAttributes: 30,
    );

WebDataStats _webData() => const WebDataStats(
      activeSources: 4,
      runningJobs: 1,
      productsScrapedToday: 500,
    );

QuickstartStats _quickstart() => const QuickstartStats(
      activeBusinessTypes: 10,
      activeTemplates: 25,
    );

ServiceHealth _health(String s, ServiceStatus status) =>
    ServiceHealth(service: s, status: status, latencyMs: 40);

DashboardStats _buildFullStats() => DashboardStats(
      iam: _iam(),
      pim: _pim(),
      webData: _webData(),
      quickstart: _quickstart(),
      services: [
        _health('iam', ServiceStatus.online),
        _health('pim', ServiceStatus.online),
        _health('webdata', ServiceStatus.degraded),
      ],
      loadedAt: DateTime(2026, 5, 31, 10),
    );

DashboardStats _buildPartialStats() => DashboardStats(
      iam: _iam(),
      pim: null,
      webData: _webData(),
      quickstart: null,
      services: [
        _health('iam', ServiceStatus.online),
        _health('pim', ServiceStatus.offline),
      ],
      loadedAt: DateTime(2026, 5, 31, 10),
    );

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Widget _buildTestApp(MockDashboardBloc bloc) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => BlocProvider<DashboardBloc>.value(
          value: bloc,
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/iam/tenants/new',
        builder: (context, state) =>
            const Scaffold(body: Text('Nuevo Tenant')),
      ),
      GoRoute(
        path: '/pim/brands/new',
        builder: (context, state) =>
            const Scaffold(body: Text('Nueva Marca')),
      ),
      GoRoute(
        path: '/web-data/sources',
        builder: (context, state) =>
            const Scaffold(body: Text('Fuentes')),
      ),
      GoRoute(
        path: '/pim/attributes/new',
        builder: (context, state) =>
            const Scaffold(body: Text('Nuevo Atributo')),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

/// Configura un viewport grande (desktop) para evitar overflow en tests de layout.
void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

/// Fallback para mocktail
class _FakeAdminDashboardEvent extends Fake implements DashboardEvent {}

void main() {
  late MockDashboardBloc bloc;

  setUpAll(() {
    registerFallbackValue(_FakeAdminDashboardEvent());
  });

  setUp(() {
    bloc = MockDashboardBloc();
  });

  group('DashboardScreen — estado Loading', () {
    setUp(() {
      when(() => bloc.state).thenReturn(DashboardLoading());
    });

    testWidgets('muestra el titulo Dashboard', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('muestra indicador de carga en el boton refresh', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('DashboardScreen — estado Loaded completo', () {
    late DashboardLoaded loadedState;

    setUp(() {
      loadedState = DashboardLoaded(
        stats: _buildFullStats(),
        lastRefreshedAt: DateTime(2026, 5, 31, 10, 30),
      );
      when(() => bloc.state).thenReturn(loadedState);
    });

    testWidgets('muestra las 4 tarjetas de secciones', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      expect(find.text('IAM'), findsOneWidget);
      expect(find.text('PIM'), findsOneWidget);
      expect(find.text('Web Data'), findsOneWidget);
      expect(find.text('Quickstart'), findsOneWidget);
    });

    testWidgets('muestra chips de salud de servicios', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      expect(find.text('iam'), findsOneWidget);
      expect(find.text('pim'), findsOneWidget);
      expect(find.text('webdata'), findsOneWidget);
    });

    testWidgets('muestra los 4 botones de accion rapida', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      // Scroll hasta el final del listado para ver quick actions
      await tester.dragUntilVisible(
        find.text('Nuevo Tenant'),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      await tester.pump();

      expect(find.text('Nuevo Tenant'), findsOneWidget);
      expect(find.text('Nueva Marca'), findsOneWidget);
      expect(find.text('Trigger Fuente'), findsOneWidget);
      expect(find.text('Nuevo Atributo'), findsOneWidget);
    });

    testWidgets('muestra label de auto-refresh', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      await tester.dragUntilVisible(
        find.text('Auto-refresh: 60s'),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      await tester.pump();

      expect(find.text('Auto-refresh: 60s'), findsOneWidget);
    });

    testWidgets('muestra el timestamp del ultimo refresh', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      expect(find.text('Actualizado: 10:30'), findsOneWidget);
    });

    testWidgets('boton refresh dispara AdminDashboardRefreshEvent', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      // El refresh button está en el SliverAppBar, siempre visible
      final refreshButton = find.byTooltip('Actualizar');
      expect(refreshButton, findsOneWidget);
      await tester.tap(refreshButton);

      verify(() => bloc.add(any(that: isA<AdminDashboardRefreshEvent>()))).called(1);
    });

    testWidgets('click en Nuevo Tenant navega a /iam/tenants/new',
        (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      await tester.dragUntilVisible(
        find.text('Nuevo Tenant'),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      await tester.pump();

      await tester.tap(find.text('Nuevo Tenant'));
      await tester.pumpAndSettle();

      // La ruta destino tiene un Scaffold con Text 'Nuevo Tenant'
      expect(find.text('Nuevo Tenant'), findsOneWidget);
    });

    testWidgets('click en Trigger Fuente navega a /web-data/sources',
        (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      await tester.dragUntilVisible(
        find.text('Trigger Fuente'),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      await tester.pump();

      await tester.tap(find.text('Trigger Fuente'));
      await tester.pumpAndSettle();

      expect(find.text('Fuentes'), findsOneWidget);
    });
  });

  group('DashboardScreen — estado Loaded con datos parciales (degradado)', () {
    setUp(() {
      when(() => bloc.state).thenReturn(
        DashboardLoaded(
          stats: _buildPartialStats(),
          lastRefreshedAt: DateTime(2026, 5, 31, 10),
        ),
      );
    });

    testWidgets('IAM card muestra datos normales', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      expect(find.text('IAM'), findsOneWidget);
    });

    testWidgets('PIM y Quickstart cards muestran Datos no disponibles', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      // PIM null + Quickstart null = 2 tarjetas con error
      expect(find.text('Datos no disponibles'), findsWidgets);
    });

    testWidgets('chip de pim presente aunque offline', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      expect(find.text('pim'), findsOneWidget);
    });
  });

  group('DashboardScreen — estado Error', () {
    setUp(() {
      when(() => bloc.state)
          .thenReturn(DashboardError('Error de conexión'));
    });

    testWidgets('muestra titulo Dashboard en estado error', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('boton refresh visible en estado error', (tester) async {
      _setDesktopViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      expect(find.byTooltip('Actualizar'), findsOneWidget);
    });
  });
}
