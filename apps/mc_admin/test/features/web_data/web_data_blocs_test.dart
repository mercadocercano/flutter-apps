import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/web_data/blocs/web_data_dashboard_bloc.dart';
import 'package:mc_admin/features/web_data/blocs/sources_bloc.dart';
import 'package:mc_admin/features/web_data/blocs/source_form_bloc.dart';
import 'package:mc_admin/features/web_data/blocs/jobs_bloc.dart';
import 'package:mc_admin/features/web_data/blocs/web_products_bloc.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockGetDashboardStatsUseCase extends Mock
    implements GetDashboardStatsUseCase {}

class MockListJobsUseCase extends Mock implements ListJobsUseCase {}

class MockListSourcesUseCase extends Mock implements ListSourcesUseCase {}

class MockTriggerSourceUseCase extends Mock implements TriggerSourceUseCase {}

class MockDeleteSourceUseCase extends Mock implements DeleteSourceUseCase {}

class MockGetSourceUseCase extends Mock implements GetSourceUseCase {}

class MockCreateSourceUseCase extends Mock implements CreateSourceUseCase {}

class MockUpdateSourceUseCase extends Mock implements UpdateSourceUseCase {}

class MockCancelJobUseCase extends Mock implements CancelJobUseCase {}

class MockRetryJobUseCase extends Mock implements RetryJobUseCase {}

class MockListWebProductsUseCase extends Mock
    implements ListWebProductsUseCase {}

class MockDeleteWebProductUseCase extends Mock
    implements DeleteWebProductUseCase {}

class MockBulkDeleteWebProductsUseCase extends Mock
    implements BulkDeleteWebProductsUseCase {}

class MockAssignBusinessTypeUseCase extends Mock
    implements AssignBusinessTypeUseCase {}

class MockBulkAssignBusinessTypeUseCase extends Mock
    implements BulkAssignBusinessTypeUseCase {}

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

final _now = DateTime(2024, 6, 15, 10);

WebDataDashboardStats _buildStats() => const WebDataDashboardStats(
      activeSources: 5,
      inactiveSources: 2,
      jobsToday: 10,
      totalProducts: 3500,
      successRate: 0.87,
    );

WebJob _buildJob({
  String id = 'job-1',
  WebJobStatus status = WebJobStatus.completed,
}) =>
    WebJob(
      id: id,
      sourceId: 'src-1',
      status: status,
      progress: 1.0,
      productsFound: 100,
      startedAt: _now,
    );

WebSource _buildSource({String id = 'src-1'}) => WebSource(
      id: id,
      name: 'MercadoLibre Ferretería',
      url: 'https://example.com',
      status: WebSourceStatus.active,
      businessTypeIds: const ['bt-1'],
      createdAt: _now,
      updatedAt: _now,
    );

WebProduct _buildProduct({String id = 'prod-1'}) => WebProduct(
      id: id,
      sourceId: 'src-1',
      name: 'Martillo 16oz',
      price: 4500.0,
      url: 'https://example.com/martillo',
      scrapedAt: _now,
    );

PaginatedResult<T> _buildPage<T>(List<T> items) => PaginatedResult<T>(
      items: items,
      totalCount: items.length,
      page: 1,
      pageSize: 20,
      totalPages: 1,
    );

DioException _buildDioException({int statusCode = 500}) => DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: statusCode,
      ),
    );

// ---------------------------------------------------------------------------
// Fallback values — requerido por mocktail para tipos de dominio
// ---------------------------------------------------------------------------

class _FakeWebSource extends Fake implements WebSource {}

class _FakeWebProduct extends Fake implements WebProduct {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeWebSource());
    registerFallbackValue(_FakeWebProduct());
  });

// ---------------------------------------------------------------------------
// WebDataDashboardBloc tests
// ---------------------------------------------------------------------------

group('WebDataDashboardBloc', () {
  late MockGetDashboardStatsUseCase mockGetStats;
  late MockListJobsUseCase mockListJobs;

  setUp(() {
    mockGetStats = MockGetDashboardStatsUseCase();
    mockListJobs = MockListJobsUseCase();
  });

  WebDataDashboardBloc buildBloc() => WebDataDashboardBloc(
        getStats: mockGetStats,
        listJobs: mockListJobs,
      );

  blocTest<WebDataDashboardBloc, WebDataDashboardState>(
    'emite Loading → Loaded con stats y jobs recientes',
    build: () {
      when(() => mockGetStats.execute()).thenAnswer((_) async => _buildStats());
      when(() => mockListJobs.execute(pageSize: 5))
          .thenAnswer((_) async => _buildPage([_buildJob()]));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadDashboardEvent()),
    expect: () => [
      isA<WebDataDashboardLoading>(),
      isA<WebDataDashboardLoaded>(),
    ],
    verify: (bloc) {
      final loaded = bloc.state as WebDataDashboardLoaded;
      expect(loaded.stats.activeSources, 5);
      expect(loaded.recentJobs, hasLength(1));
    },
  );

  blocTest<WebDataDashboardBloc, WebDataDashboardState>(
    'emite Error cuando getStats falla',
    build: () {
      when(() => mockGetStats.execute())
          .thenThrow(Exception('Network error'));
      when(() => mockListJobs.execute(pageSize: 5))
          .thenAnswer((_) async => _buildPage([]));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadDashboardEvent()),
    expect: () => [
      isA<WebDataDashboardLoading>(),
      isA<WebDataDashboardError>(),
    ],
  );

  blocTest<WebDataDashboardBloc, WebDataDashboardState>(
    'Refresh vuelve a llamar a Load',
    build: () {
      when(() => mockGetStats.execute()).thenAnswer((_) async => _buildStats());
      when(() => mockListJobs.execute(pageSize: 5))
          .thenAnswer((_) async => _buildPage([_buildJob()]));
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(LoadDashboardEvent());
      await Future.delayed(Duration.zero);
      bloc.add(RefreshDashboardEvent());
    },
    expect: () => [
      isA<WebDataDashboardLoading>(),
      isA<WebDataDashboardLoaded>(),
      isA<WebDataDashboardLoading>(),
      isA<WebDataDashboardLoaded>(),
    ],
  );
});

// ---------------------------------------------------------------------------
// SourcesBloc tests
// ---------------------------------------------------------------------------

group('SourcesBloc', () {
  late MockListSourcesUseCase mockList;
  late MockTriggerSourceUseCase mockTrigger;
  late MockDeleteSourceUseCase mockDelete;

  setUp(() {
    mockList = MockListSourcesUseCase();
    mockTrigger = MockTriggerSourceUseCase();
    mockDelete = MockDeleteSourceUseCase();
  });

  SourcesBloc buildBloc() => SourcesBloc(
        list: mockList,
        trigger: mockTrigger,
        delete: mockDelete,
      );

  blocTest<SourcesBloc, SourcesState>(
    'emite Loading → Loaded con lista de fuentes',
    build: () {
      when(() => mockList.execute(status: any(named: 'status')))
          .thenAnswer((_) async => _buildPage([_buildSource()]));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadSourcesEvent()),
    expect: () => [isA<SourcesLoading>(), isA<SourcesLoaded>()],
    verify: (bloc) {
      final loaded = bloc.state as SourcesLoaded;
      expect(loaded.sources, hasLength(1));
    },
  );

  blocTest<SourcesBloc, SourcesState>(
    'filtra por status cuando se proporciona',
    build: () {
      when(() => mockList.execute(status: 'active'))
          .thenAnswer((_) async => _buildPage([_buildSource()]));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadSourcesEvent(status: 'active')),
    expect: () => [isA<SourcesLoading>(), isA<SourcesLoaded>()],
    verify: (bloc) {
      final loaded = bloc.state as SourcesLoaded;
      expect(loaded.statusFilter, 'active');
    },
  );

  blocTest<SourcesBloc, SourcesState>(
    'Trigger llama al use case y refresca',
    build: () {
      when(() => mockList.execute(status: any(named: 'status')))
          .thenAnswer((_) async => _buildPage([_buildSource()]));
      when(() => mockTrigger.execute('src-1'))
          .thenAnswer((_) async => _buildJob());
      return buildBloc();
    },
    seed: () => SourcesLoaded(sources: [_buildSource()]),
    act: (bloc) => bloc.add(TriggerSourceEvent('src-1')),
    expect: () => [isA<SourcesLoading>(), isA<SourcesLoaded>()],
    verify: (_) => verify(() => mockTrigger.execute('src-1')).called(1),
  );

  blocTest<SourcesBloc, SourcesState>(
    'Delete con 409 emite Error con mensaje de conflicto',
    build: () {
      when(() => mockDelete.execute('src-1'))
          .thenThrow(_buildDioException(statusCode: 409));
      return buildBloc();
    },
    seed: () => SourcesLoaded(sources: [_buildSource()]),
    act: (bloc) => bloc.add(DeleteSourceEvent('src-1')),
    expect: () => [isA<SourcesError>()],
    verify: (bloc) {
      final err = bloc.state as SourcesError;
      expect(err.message, contains('jobs en ejecución'));
    },
  );

  blocTest<SourcesBloc, SourcesState>(
    'emite Error cuando list falla',
    build: () {
      when(() => mockList.execute(status: any(named: 'status')))
          .thenThrow(Exception('timeout'));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadSourcesEvent()),
    expect: () => [isA<SourcesLoading>(), isA<SourcesError>()],
  );
});

// ---------------------------------------------------------------------------
// SourceFormBloc tests
// ---------------------------------------------------------------------------

group('SourceFormBloc', () {
  late MockGetSourceUseCase mockGet;
  late MockCreateSourceUseCase mockCreate;
  late MockUpdateSourceUseCase mockUpdate;

  setUp(() {
    mockGet = MockGetSourceUseCase();
    mockCreate = MockCreateSourceUseCase();
    mockUpdate = MockUpdateSourceUseCase();
  });

  SourceFormBloc buildBloc() => SourceFormBloc(
        get: mockGet,
        create: mockCreate,
        update: mockUpdate,
      );

  blocTest<SourceFormBloc, SourceFormState>(
    'LoadSource emite Loading → Success con la fuente',
    build: () {
      when(() => mockGet.execute('src-1'))
          .thenAnswer((_) async => _buildSource());
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadSourceEvent('src-1')),
    expect: () => [isA<SourceFormLoading>(), isA<SourceFormSuccess>()],
    verify: (bloc) {
      final success = bloc.state as SourceFormSuccess;
      expect(success.source.id, 'src-1');
    },
  );

  blocTest<SourceFormBloc, SourceFormState>(
    'Submit con id vacío crea fuente nueva',
    build: () {
      when(() => mockCreate.execute(any()))
          .thenAnswer((_) async => _buildSource());
      return buildBloc();
    },
    act: (bloc) {
      final newSource = _buildSource(id: '');
      bloc.add(SubmitSourceFormEvent(newSource));
    },
    expect: () => [isA<SourceFormLoading>(), isA<SourceFormSuccess>()],
    verify: (_) => verify(() => mockCreate.execute(any())).called(1),
  );

  blocTest<SourceFormBloc, SourceFormState>(
    'Submit con id existente actualiza la fuente',
    build: () {
      when(() => mockUpdate.execute(any()))
          .thenAnswer((_) async => _buildSource());
      return buildBloc();
    },
    act: (bloc) => bloc.add(SubmitSourceFormEvent(_buildSource())),
    expect: () => [isA<SourceFormLoading>(), isA<SourceFormSuccess>()],
    verify: (_) => verify(() => mockUpdate.execute(any())).called(1),
  );

  blocTest<SourceFormBloc, SourceFormState>(
    '409 emite Error con mensaje de conflicto de URL',
    build: () {
      when(() => mockCreate.execute(any()))
          .thenThrow(_buildDioException(statusCode: 409));
      return buildBloc();
    },
    act: (bloc) => bloc.add(SubmitSourceFormEvent(_buildSource(id: ''))),
    expect: () => [isA<SourceFormLoading>(), isA<SourceFormError>()],
    verify: (bloc) {
      final err = bloc.state as SourceFormError;
      expect(err.message, contains('URL'));
    },
  );

  blocTest<SourceFormBloc, SourceFormState>(
    'Reset emite Initial',
    build: buildBloc,
    act: (bloc) => bloc.add(ResetSourceFormEvent()),
    expect: () => [isA<SourceFormInitial>()],
  );
});

// ---------------------------------------------------------------------------
// JobsBloc tests (incluye polling con fake timer)
// ---------------------------------------------------------------------------

group('JobsBloc', () {
  late MockListJobsUseCase mockList;
  late MockCancelJobUseCase mockCancel;
  late MockRetryJobUseCase mockRetry;

  setUp(() {
    mockList = MockListJobsUseCase();
    mockCancel = MockCancelJobUseCase();
    mockRetry = MockRetryJobUseCase();
  });

  JobsBloc buildBloc({TimerFactory? timerFactory}) => JobsBloc(
        list: mockList,
        cancel: mockCancel,
        retry: mockRetry,
        timerFactory: timerFactory ?? Timer.periodic,
      );

  blocTest<JobsBloc, JobsState>(
    'LoadJobs emite Loading → Loaded con jobs',
    build: () {
      when(() => mockList.execute(
            status: any(named: 'status'),
            sourceId: any(named: 'sourceId'),
          )).thenAnswer((_) async => _buildPage([_buildJob()]));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadJobsEvent()),
    expect: () => [isA<JobsLoading>(), isA<JobsLoaded>()],
    verify: (bloc) {
      final loaded = bloc.state as JobsLoaded;
      expect(loaded.jobs, hasLength(1));
      expect(loaded.hasRunningJobs, isFalse);
    },
  );

  blocTest<JobsBloc, JobsState>(
    'hasRunningJobs=true cuando hay jobs running',
    build: () {
      when(() => mockList.execute(
            status: any(named: 'status'),
            sourceId: any(named: 'sourceId'),
          )).thenAnswer(
        (_) async => _buildPage([
          _buildJob(id: 'job-running', status: WebJobStatus.running),
        ]),
      );
      return buildBloc(timerFactory: (duration, _) => Timer(Duration.zero, () {}));
    },
    act: (bloc) => bloc.add(LoadJobsEvent()),
    expect: () => [isA<JobsLoading>(), isA<JobsLoaded>()],
    verify: (bloc) {
      final loaded = bloc.state as JobsLoaded;
      expect(loaded.hasRunningJobs, isTrue);
    },
  );

  test('polling: el timer se llama cuando hay jobs running', () async {
    // Arrange: primera carga trae un job running
    when(() => mockList.execute(
          status: any(named: 'status'),
          sourceId: any(named: 'sourceId'),
        )).thenAnswer(
      (_) async => _buildPage([
        _buildJob(id: 'job-running', status: WebJobStatus.running),
      ]),
    );

    var timerCreated = false;
    Timer fakeTimerCreator(Duration duration, void Function(Timer) callback) {
      timerCreated = true;
      expect(duration, const Duration(seconds: 5));
      return Timer(Duration.zero, () {});
    }

    final bloc = buildBloc(timerFactory: fakeTimerCreator);
    bloc.add(LoadJobsEvent());
    await Future.delayed(const Duration(milliseconds: 100));

    expect(timerCreated, isTrue);
    await bloc.close();
  });

  test('polling: el timer NO se crea cuando no hay running jobs', () async {
    when(() => mockList.execute(
          status: any(named: 'status'),
          sourceId: any(named: 'sourceId'),
        )).thenAnswer((_) async => _buildPage([_buildJob()]));

    var timerCreated = false;
    Timer noOpTimerCreator(Duration duration, void Function(Timer) callback) {
      timerCreated = true;
      return Timer(Duration.zero, () {});
    }

    final bloc = buildBloc(timerFactory: noOpTimerCreator);
    bloc.add(LoadJobsEvent());
    await Future.delayed(const Duration(milliseconds: 100));

    expect(timerCreated, isFalse);
    await bloc.close();
  });

  test('polling: PollTick refresca y detiene timer cuando no quedan running', () async {
    var callCount = 0;
    // Primera llamada: running. Segunda (poll tick): completed.
    when(() => mockList.execute(
          status: any(named: 'status'),
          sourceId: any(named: 'sourceId'),
        )).thenAnswer((_) async {
      callCount++;
      final status =
          callCount == 1 ? WebJobStatus.running : WebJobStatus.completed;
      return _buildPage([_buildJob(status: status)]);
    });

    Timer? capturedTimer;
    void Function(Timer)? capturedCallback;

    Timer capturingTimerCreator(Duration duration, void Function(Timer) callback) {
      capturedCallback = callback;
      capturedTimer = Timer(Duration.zero, () {});
      return capturedTimer!;
    }

    final bloc = buildBloc(timerFactory: capturingTimerCreator);

    // Arrange: cargar con job running
    bloc.add(LoadJobsEvent());
    await Future.delayed(const Duration(milliseconds: 50));

    // Simular tick del timer
    capturedCallback?.call(capturedTimer!);
    await Future.delayed(const Duration(milliseconds: 50));

    // El estado final debe mostrar hasRunningJobs=false
    expect(bloc.state, isA<JobsLoaded>());
    final loaded = bloc.state as JobsLoaded;
    expect(loaded.hasRunningJobs, isFalse);

    await bloc.close();
  });

  blocTest<JobsBloc, JobsState>(
    'StopPolling no genera error aunque no haya timer activo',
    build: () {
      when(() => mockList.execute(
            status: any(named: 'status'),
            sourceId: any(named: 'sourceId'),
          )).thenAnswer((_) async => _buildPage([_buildJob()]));
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(LoadJobsEvent());
      await Future.delayed(Duration.zero);
      bloc.add(StopPollingEvent());
    },
    expect: () => [isA<JobsLoading>(), isA<JobsLoaded>()],
  );

  blocTest<JobsBloc, JobsState>(
    'CancelJob llama al use case y refresca',
    build: () {
      when(() => mockList.execute(
            status: any(named: 'status'),
            sourceId: any(named: 'sourceId'),
          )).thenAnswer((_) async => _buildPage([_buildJob()]));
      when(() => mockCancel.execute('job-1')).thenAnswer((_) async {});
      return buildBloc();
    },
    seed: () => JobsLoaded(
      jobs: [_buildJob()],
      hasRunningJobs: false,
    ),
    act: (bloc) => bloc.add(CancelJobEvent('job-1')),
    expect: () => [isA<JobsLoading>(), isA<JobsLoaded>()],
    verify: (_) => verify(() => mockCancel.execute('job-1')).called(1),
  );

  blocTest<JobsBloc, JobsState>(
    'RetryJob llama al use case y refresca',
    build: () {
      when(() => mockList.execute(
            status: any(named: 'status'),
            sourceId: any(named: 'sourceId'),
          )).thenAnswer((_) async => _buildPage([_buildJob()]));
      when(() => mockRetry.execute('job-1'))
          .thenAnswer((_) async => _buildJob());
      return buildBloc();
    },
    seed: () => JobsLoaded(
      jobs: [_buildJob()],
      hasRunningJobs: false,
    ),
    act: (bloc) => bloc.add(RetryJobEvent('job-1')),
    expect: () => [isA<JobsLoading>(), isA<JobsLoaded>()],
    verify: (_) => verify(() => mockRetry.execute('job-1')).called(1),
  );

  blocTest<JobsBloc, JobsState>(
    'emite Error cuando listJobs falla',
    build: () {
      when(() => mockList.execute(
            status: any(named: 'status'),
            sourceId: any(named: 'sourceId'),
          )).thenThrow(Exception('timeout'));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadJobsEvent()),
    expect: () => [isA<JobsLoading>(), isA<JobsError>()],
  );
});

// ---------------------------------------------------------------------------
// WebProductsBloc tests
// ---------------------------------------------------------------------------

group('WebProductsBloc', () {
  late MockListWebProductsUseCase mockList;
  late MockDeleteWebProductUseCase mockDelete;
  late MockBulkDeleteWebProductsUseCase mockBulkDelete;
  late MockAssignBusinessTypeUseCase mockAssign;
  late MockBulkAssignBusinessTypeUseCase mockBulkAssign;

  setUp(() {
    mockList = MockListWebProductsUseCase();
    mockDelete = MockDeleteWebProductUseCase();
    mockBulkDelete = MockBulkDeleteWebProductsUseCase();
    mockAssign = MockAssignBusinessTypeUseCase();
    mockBulkAssign = MockBulkAssignBusinessTypeUseCase();
  });

  WebProductsBloc buildBloc() => WebProductsBloc(
        list: mockList,
        delete: mockDelete,
        bulkDelete: mockBulkDelete,
        assign: mockAssign,
        bulkAssign: mockBulkAssign,
      );

  void stubList({List<WebProduct>? products}) {
    when(() => mockList.execute(
          sourceId: any(named: 'sourceId'),
          businessTypeId: any(named: 'businessTypeId'),
        )).thenAnswer((_) async => _buildPage(products ?? [_buildProduct()]));
  }

  blocTest<WebProductsBloc, WebProductsState>(
    'LoadWebProducts emite Loading → Loaded con lista vacía de selectedIds',
    build: () {
      stubList();
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadWebProductsEvent()),
    expect: () => [isA<WebProductsLoading>(), isA<WebProductsLoaded>()],
    verify: (bloc) {
      final loaded = bloc.state as WebProductsLoaded;
      expect(loaded.products, hasLength(1));
      expect(loaded.selectedIds, isEmpty);
      expect(loaded.hasSelection, isFalse);
    },
  );

  blocTest<WebProductsBloc, WebProductsState>(
    'SelectProduct agrega id a selectedIds',
    build: buildBloc,
    seed: () => WebProductsLoaded(
      products: [_buildProduct()],
      selectedIds: const {},
    ),
    act: (bloc) => bloc.add(SelectProductEvent('prod-1')),
    expect: () => [
      isA<WebProductsLoaded>().having(
        (s) => s.selectedIds,
        'selectedIds',
        contains('prod-1'),
      ),
    ],
  );

  blocTest<WebProductsBloc, WebProductsState>(
    'DeselectProduct elimina id de selectedIds',
    build: buildBloc,
    seed: () => WebProductsLoaded(
      products: [_buildProduct()],
      selectedIds: const {'prod-1'},
    ),
    act: (bloc) => bloc.add(DeselectProductEvent('prod-1')),
    expect: () => [
      isA<WebProductsLoaded>().having(
        (s) => s.selectedIds,
        'selectedIds',
        isEmpty,
      ),
    ],
  );

  blocTest<WebProductsBloc, WebProductsState>(
    'SelectAll selecciona todos los productos',
    build: buildBloc,
    seed: () => WebProductsLoaded(
      products: [_buildProduct(id: 'p1'), _buildProduct(id: 'p2')],
      selectedIds: const {},
    ),
    act: (bloc) => bloc.add(SelectAllProductsEvent()),
    expect: () => [
      isA<WebProductsLoaded>().having(
        (s) => s.allSelected,
        'allSelected',
        isTrue,
      ),
    ],
  );

  blocTest<WebProductsBloc, WebProductsState>(
    'DeselectAll limpia selectedIds',
    build: buildBloc,
    seed: () => WebProductsLoaded(
      products: [_buildProduct()],
      selectedIds: const {'prod-1'},
    ),
    act: (bloc) => bloc.add(DeselectAllProductsEvent()),
    expect: () => [
      isA<WebProductsLoaded>().having(
        (s) => s.selectedIds,
        'selectedIds',
        isEmpty,
      ),
    ],
  );

  blocTest<WebProductsBloc, WebProductsState>(
    'DeleteProduct llama al use case y recarga la lista',
    build: () {
      stubList();
      when(() => mockDelete.execute('prod-1')).thenAnswer((_) async {});
      return buildBloc();
    },
    seed: () => WebProductsLoaded(
      products: [_buildProduct()],
      selectedIds: const {},
    ),
    act: (bloc) => bloc.add(DeleteWebProductEvent('prod-1')),
    expect: () => [isA<WebProductsLoaded>()],
    verify: (_) => verify(() => mockDelete.execute('prod-1')).called(1),
  );

  blocTest<WebProductsBloc, WebProductsState>(
    'BulkDelete elimina los seleccionados y recarga',
    build: () {
      stubList(products: []);
      when(() => mockBulkDelete.execute(['prod-1', 'prod-2']))
          .thenAnswer((_) async {});
      return buildBloc();
    },
    seed: () => WebProductsLoaded(
      products: [_buildProduct(id: 'prod-1'), _buildProduct(id: 'prod-2')],
      selectedIds: const {'prod-1', 'prod-2'},
    ),
    act: (bloc) => bloc.add(BulkDeleteWebProductsEvent()),
    expect: () => [isA<WebProductsLoaded>()],
    verify: (_) =>
        verify(() => mockBulkDelete.execute(any())).called(1),
  );

  blocTest<WebProductsBloc, WebProductsState>(
    'BulkDelete sin selección no hace nada',
    build: buildBloc,
    seed: () => WebProductsLoaded(
      products: [_buildProduct()],
      selectedIds: const {},
    ),
    act: (bloc) => bloc.add(BulkDeleteWebProductsEvent()),
    expect: () => [],
  );

  blocTest<WebProductsBloc, WebProductsState>(
    'AssignBusinessType llama al use case individual y recarga',
    build: () {
      stubList();
      when(() => mockAssign.execute('prod-1', 'bt-1'))
          .thenAnswer((_) async => _buildProduct());
      return buildBloc();
    },
    seed: () => WebProductsLoaded(
      products: [_buildProduct()],
      selectedIds: const {},
    ),
    act: (bloc) => bloc.add(
      AssignBusinessTypeEvent(id: 'prod-1', businessTypeId: 'bt-1'),
    ),
    expect: () => [isA<WebProductsLoaded>()],
    verify: (_) => verify(() => mockAssign.execute('prod-1', 'bt-1')).called(1),
  );

  blocTest<WebProductsBloc, WebProductsState>(
    'BulkAssignBusinessType asigna a todos los seleccionados',
    build: () {
      stubList();
      when(() => mockBulkAssign.execute(any(), 'bt-2'))
          .thenAnswer((_) async {});
      return buildBloc();
    },
    seed: () => WebProductsLoaded(
      products: [_buildProduct(id: 'p1'), _buildProduct(id: 'p2')],
      selectedIds: const {'p1', 'p2'},
    ),
    act: (bloc) => bloc.add(BulkAssignBusinessTypeEvent('bt-2')),
    expect: () => [isA<WebProductsLoaded>()],
    verify: (_) =>
        verify(() => mockBulkAssign.execute(any(), 'bt-2')).called(1),
  );

  blocTest<WebProductsBloc, WebProductsState>(
    'BulkAssign sin selección no hace nada',
    build: buildBloc,
    seed: () => WebProductsLoaded(
      products: [_buildProduct()],
      selectedIds: const {},
    ),
    act: (bloc) => bloc.add(BulkAssignBusinessTypeEvent('bt-2')),
    expect: () => [],
  );

  blocTest<WebProductsBloc, WebProductsState>(
    'emite Error cuando list falla',
    build: () {
      when(() => mockList.execute(
            sourceId: any(named: 'sourceId'),
            businessTypeId: any(named: 'businessTypeId'),
          )).thenThrow(Exception('timeout'));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadWebProductsEvent()),
    expect: () => [isA<WebProductsLoading>(), isA<WebProductsError>()],
  );
});
} // end main
