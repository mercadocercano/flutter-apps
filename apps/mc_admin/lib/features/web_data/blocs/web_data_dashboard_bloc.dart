import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class WebDataDashboardEvent {}

class LoadDashboardEvent extends WebDataDashboardEvent {}

class RefreshDashboardEvent extends WebDataDashboardEvent {}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class WebDataDashboardState {}

class WebDataDashboardInitial extends WebDataDashboardState {}

class WebDataDashboardLoading extends WebDataDashboardState {}

class WebDataDashboardLoaded extends WebDataDashboardState {
  final WebDataDashboardStats stats;
  final List<WebJob> recentJobs;

  WebDataDashboardLoaded({
    required this.stats,
    required this.recentJobs,
  });
}

class WebDataDashboardError extends WebDataDashboardState {
  final String message;
  WebDataDashboardError(this.message);
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class WebDataDashboardBloc
    extends Bloc<WebDataDashboardEvent, WebDataDashboardState> {
  final GetDashboardStatsUseCase _getStats;
  final ListJobsUseCase _listJobs;

  WebDataDashboardBloc({
    required GetDashboardStatsUseCase getStats,
    required ListJobsUseCase listJobs,
  })  : _getStats = getStats,
        _listJobs = listJobs,
        super(WebDataDashboardInitial()) {
    on<LoadDashboardEvent>(_onLoad);
    on<RefreshDashboardEvent>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadDashboardEvent event,
    Emitter<WebDataDashboardState> emit,
  ) async {
    emit(WebDataDashboardLoading());

    try {
      final results = await Future.wait([
        _getStats.execute(),
        _listJobs.execute(pageSize: 5),
      ]);

      final stats = results[0] as WebDataDashboardStats;
      final jobsPage = results[1] as PaginatedResult<WebJob>;

      emit(WebDataDashboardLoaded(
        stats: stats,
        recentJobs: jobsPage.items,
      ));
    } catch (e) {
      emit(WebDataDashboardError('Error al cargar dashboard: $e'));
    }
  }

  Future<void> _onRefresh(
    RefreshDashboardEvent event,
    Emitter<WebDataDashboardState> emit,
  ) async {
    add(LoadDashboardEvent());
  }
}
