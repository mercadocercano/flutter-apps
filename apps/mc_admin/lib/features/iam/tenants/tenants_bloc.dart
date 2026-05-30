import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class TenantsEvent {}

class LoadTenantsEvent extends TenantsEvent {
  final int page;
  final int pageSize;
  final String? searchQuery;
  final TenantStatus? status;
  final TenantType? type;

  LoadTenantsEvent({
    this.page = 1,
    this.pageSize = 20,
    this.searchQuery,
    this.status,
    this.type,
  });
}

class ChangeTenantsPageEvent extends TenantsEvent {
  final int page;
  ChangeTenantsPageEvent(this.page);
}

// --- States ---

abstract class TenantsState {}

class TenantsInitial extends TenantsState {}

class TenantsLoading extends TenantsState {}

class TenantsLoaded extends TenantsState {
  final List<Tenant> tenants;
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final String? searchQuery;
  final TenantStatus? filterStatus;
  final TenantType? filterType;

  TenantsLoaded({
    required this.tenants,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    this.searchQuery,
    this.filterStatus,
    this.filterType,
  });

  int get totalPages => pageSize > 0 ? (totalItems / pageSize).ceil() : 1;
}

class TenantsError extends TenantsState {
  final String message;
  TenantsError(this.message);
}

// --- Bloc ---

class TenantsBloc extends Bloc<TenantsEvent, TenantsState> {
  final GetTenantsUseCase _getAll;

  int _currentPage = 1;
  int _pageSize = 20;
  TenantStatus? _filterStatus;
  TenantType? _filterType;

  TenantsBloc({required GetTenantsUseCase getAll})
      : _getAll = getAll,
        super(TenantsInitial()) {
    on<LoadTenantsEvent>(_onLoad);
    on<ChangeTenantsPageEvent>(_onChangePage);
  }

  Future<void> _onLoad(
    LoadTenantsEvent event,
    Emitter<TenantsState> emit,
  ) async {
    emit(TenantsLoading());
    _currentPage = event.page;
    _pageSize = event.pageSize;
    _filterStatus = event.status;
    _filterType = event.type;

    try {
      final result = await _getAll.execute(
        _currentPage,
        _pageSize,
        status: _filterStatus,
        type: _filterType,
      );
      emit(TenantsLoaded(
        tenants: result.items,
        currentPage: result.page,
        pageSize: result.pageSize,
        totalItems: result.totalCount,
        searchQuery: event.searchQuery,
        filterStatus: _filterStatus,
        filterType: _filterType,
      ));
    } catch (e) {
      emit(TenantsError('Error al cargar tenants: $e'));
    }
  }

  Future<void> _onChangePage(
    ChangeTenantsPageEvent event,
    Emitter<TenantsState> emit,
  ) async {
    add(LoadTenantsEvent(
      page: event.page,
      pageSize: _pageSize,
      status: _filterStatus,
      type: _filterType,
    ));
  }
}
