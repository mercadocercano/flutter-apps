import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/dashboard/blocs/dashboard_bloc.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockGetAdminDashboardStatsUseCase extends Mock
    implements GetAdminDashboardStatsUseCase {}

class MockRefreshDashboardUseCase extends Mock
    implements RefreshDashboardUseCase {}

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

final _now = DateTime(2026, 5, 31, 10);

IamStats _buildIam() => const IamStats(
      activeTenants: 42,
      newTenantsLast24h: 2,
      totalRoles: 5,
      totalPlans: 3,
    );

PimStats _buildPim() => const PimStats(
      totalCategories: 100,
      verifiedBrands: 50,
      totalBrands: 70,
      verifiedProducts: 2000,
      totalProducts: 3000,
      totalAttributes: 30,
    );

WebDataStats _buildWebData() => const WebDataStats(
      activeSources: 4,
      runningJobs: 1,
      productsScrapedToday: 500,
    );

QuickstartStats _buildQuickstart() => const QuickstartStats(
      activeBusinessTypes: 10,
      activeTemplates: 25,
    );

ServiceHealth _buildHealth(String s) =>
    ServiceHealth(service: s, status: ServiceStatus.online, latencyMs: 30);

DashboardStats _buildStats() => DashboardStats(
      iam: _buildIam(),
      pim: _buildPim(),
      webData: _buildWebData(),
      quickstart: _buildQuickstart(),
      services: [_buildHealth('iam'), _buildHealth('pim')],
      loadedAt: _now,
    );

DashboardStats _buildPartialStats() => DashboardStats(
      iam: _buildIam(),
      pim: null,
      webData: _buildWebData(),
      quickstart: null,
      services: [
        _buildHealth('iam'),
        ServiceHealth(service: 'pim', status: ServiceStatus.offline),
      ],
      loadedAt: _now,
    );

// ---------------------------------------------------------------------------
// Fake timer helpers
// ---------------------------------------------------------------------------

/// Timer fake que nunca dispara automáticamente.
/// Permite controlar manualmente cuándo el callback se ejecuta.
class _FakeTimer implements Timer {
  final void Function(Timer) callback;
  bool _active = true;

  _FakeTimer(this.callback);

  void fire() => callback(this);

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockGetAdminDashboardStatsUseCase mockGetStats;
  late MockRefreshDashboardUseCase mockRefresh;

  setUp(() {
    mockGetStats = MockGetAdminDashboardStatsUseCase();
    mockRefresh = MockRefreshDashboardUseCase();
  });

  DashboardBloc buildBloc({
    Timer Function(Duration, void Function(Timer))? timerFactory,
  }) {
    return DashboardBloc(
      getStats: mockGetStats,
      refresh: mockRefresh,
      timerFactory: timerFactory ?? (_, __) => _FakeTimer(__),
    );
  }

  // ─── AdminDashboardLoadEvent ───────────────────────────────────────────────────

  group('AdminDashboardLoadEvent', () {
    blocTest<DashboardBloc, DashboardState>(
      'emite [Loading, Loaded] cuando el repositorio responde',
      setUp: () {
        when(() => mockGetStats.execute())
            .thenAnswer((_) async => _buildStats());
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AdminDashboardLoadEvent()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>(),
      ],
      verify: (_) {
        verify(() => mockGetStats.execute()).called(1);
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'Loaded contiene stats y lastRefreshedAt',
      setUp: () {
        when(() => mockGetStats.execute())
            .thenAnswer((_) async => _buildStats());
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AdminDashboardLoadEvent()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>().having(
          (s) => s.stats.iam?.activeTenants,
          'activeTenants',
          42,
        ),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emite [Loading, Error] cuando el repositorio lanza excepcion',
      setUp: () {
        when(() => mockGetStats.execute())
            .thenThrow(Exception('Connection refused'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AdminDashboardLoadEvent()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardError>().having(
          (s) => s.message,
          'message contains error',
          contains('Error al cargar'),
        ),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'Loaded muestra datos parciales cuando pim es null',
      setUp: () {
        when(() => mockGetStats.execute())
            .thenAnswer((_) async => _buildPartialStats());
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AdminDashboardLoadEvent()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>().having(
          (s) => s.stats.hasPartialData,
          'hasPartialData',
          isTrue,
        ),
      ],
    );
  });

  // ─── AdminDashboardRefreshEvent ────────────────────────────────────────────────

  group('AdminDashboardRefreshEvent', () {
    blocTest<DashboardBloc, DashboardState>(
      'emite Loaded usando RefreshDashboardUseCase',
      setUp: () {
        when(() => mockGetStats.execute())
            .thenAnswer((_) async => _buildStats());
        when(() => mockRefresh.execute())
            .thenAnswer((_) async => _buildStats());
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(AdminDashboardLoadEvent());
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(AdminDashboardRefreshEvent());
      },
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>(),
        isA<DashboardLoaded>(),
      ],
      verify: (_) {
        verify(() => mockGetStats.execute()).called(1);
        verify(() => mockRefresh.execute()).called(1);
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'refresh error emite DashboardError',
      setUp: () {
        when(() => mockGetStats.execute())
            .thenAnswer((_) async => _buildStats());
        when(() => mockRefresh.execute()).thenThrow(Exception('timeout'));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(AdminDashboardLoadEvent());
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(AdminDashboardRefreshEvent());
      },
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>(),
        isA<DashboardError>(),
      ],
    );
  });

  // ─── AdminDashboardStopAutoRefreshEvent ─────────────────────────────────────────────────

  group('AdminDashboardStopAutoRefreshEvent', () {
    blocTest<DashboardBloc, DashboardState>(
      'acepta StopAutoRefresh sin emitir nuevos estados',
      setUp: () {
        when(() => mockGetStats.execute())
            .thenAnswer((_) async => _buildStats());
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(AdminDashboardLoadEvent());
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(AdminDashboardStopAutoRefreshEvent());
      },
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>(),
        // AdminDashboardStopAutoRefreshEvent no emite estado nuevo
      ],
    );
  });

  // ─── Auto-refresh con fake timer ──────────────────────────────────────────

  group('Auto-refresh', () {
    test('dispara AdminDashboardRefreshEvent cuando el timer hace tick', () async {
      when(() => mockGetStats.execute())
          .thenAnswer((_) async => _buildStats());
      when(() => mockRefresh.execute())
          .thenAnswer((_) async => _buildStats());

      _FakeTimer? capturedTimer;

      final bloc = DashboardBloc(
        getStats: mockGetStats,
        refresh: mockRefresh,
        timerFactory: (duration, callback) {
          capturedTimer = _FakeTimer(callback);
          return capturedTimer!;
        },
      );

      bloc.add(AdminDashboardLoadEvent());
      await Future.delayed(const Duration(milliseconds: 20));

      // Simula que el timer dispara
      capturedTimer?.fire();
      await Future.delayed(const Duration(milliseconds: 20));

      verify(() => mockRefresh.execute()).called(1);

      await bloc.close();
    });

    test('close() cancela el timer interno', () async {
      when(() => mockGetStats.execute())
          .thenAnswer((_) async => _buildStats());

      _FakeTimer? capturedTimer;

      final bloc = DashboardBloc(
        getStats: mockGetStats,
        refresh: mockRefresh,
        timerFactory: (duration, callback) {
          capturedTimer = _FakeTimer(callback);
          return capturedTimer!;
        },
      );

      bloc.add(AdminDashboardLoadEvent());
      await Future.delayed(const Duration(milliseconds: 20));
      await bloc.close();

      expect(capturedTimer?.isActive, isFalse);
    });
  });
}
