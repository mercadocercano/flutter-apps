import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class DashboardEvent {}

/// Carga inicial del dashboard. Arranca el auto-refresh de 60 segundos.
class AdminDashboardLoadEvent extends DashboardEvent {}

/// Refresh manual disparado por el botón de la UI.
class AdminDashboardRefreshEvent extends DashboardEvent {}

/// Detiene el timer de auto-refresh (por ejemplo al abandonar la pantalla).
class AdminDashboardStopAutoRefreshEvent extends DashboardEvent {}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final DateTime lastRefreshedAt;

  DashboardLoaded({
    required this.stats,
    required this.lastRefreshedAt,
  });
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

/// Gestiona el estado del dashboard de administración.
///
/// Auto-refresh cada 60 segundos, cancelable mediante [StopAutoRefreshEvent]
/// o el cierre del bloc. El timer es inyectable para facilitar tests con
/// `fake_async`.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  static const _refreshInterval = Duration(seconds: 60);

  final GetAdminDashboardStatsUseCase _getStats;
  final RefreshDashboardUseCase _refresh;

  /// Factory de timer inyectable para tests. Recibe (duration, callback).
  /// En producción usa [Timer.periodic] por defecto.
  final Timer Function(Duration, void Function(Timer)) _timerFactory;

  Timer? _autoRefreshTimer;

  DashboardBloc({
    required GetAdminDashboardStatsUseCase getStats,
    required RefreshDashboardUseCase refresh,
    Timer Function(Duration, void Function(Timer))? timerFactory,
  })  : _getStats = getStats,
        _refresh = refresh,
        _timerFactory = timerFactory ?? Timer.periodic,
        super(DashboardInitial()) {
    on<AdminDashboardLoadEvent>(_onLoad);
    on<AdminDashboardRefreshEvent>(_onRefresh);
    on<AdminDashboardStopAutoRefreshEvent>(_onStopAutoRefresh);
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    AdminDashboardLoadEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    await _loadStats(emit, useRefresh: false);
    _startAutoRefresh();
  }

  Future<void> _onRefresh(
    AdminDashboardRefreshEvent event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadStats(emit, useRefresh: true);
  }

  void _onStopAutoRefresh(
    AdminDashboardStopAutoRefreshEvent event,
    Emitter<DashboardState> emit,
  ) {
    _cancelTimer();
  }

  // ─── Carga de datos ───────────────────────────────────────────────────────

  Future<void> _loadStats(
    Emitter<DashboardState> emit, {
    required bool useRefresh,
  }) async {
    try {
      final stats = useRefresh
          ? await _refresh.execute()
          : await _getStats.execute();

      emit(DashboardLoaded(
        stats: stats,
        lastRefreshedAt: DateTime.now(),
      ));
    } catch (e) {
      emit(DashboardError('Error al cargar el dashboard: $e'));
    }
  }

  // ─── Auto-refresh ──────────────────────────────────────────────────────────

  void _startAutoRefresh() {
    _cancelTimer();
    _autoRefreshTimer = _timerFactory(
      _refreshInterval,
      (_) => add(AdminDashboardRefreshEvent()),
    );
  }

  void _cancelTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
