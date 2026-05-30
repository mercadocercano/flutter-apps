import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class RolesEvent {}

class LoadRolesEvent extends RolesEvent {
  final int page;
  final int pageSize;
  final String? searchQuery;
  final RoleType? type;
  final RoleStatus? status;

  LoadRolesEvent({
    this.page = 1,
    this.pageSize = 20,
    this.searchQuery,
    this.type,
    this.status,
  });
}

class ChangeRolesPageEvent extends RolesEvent {
  final int page;
  ChangeRolesPageEvent(this.page);
}

// --- States ---

abstract class RolesState {}

class RolesInitial extends RolesState {}

class RolesLoading extends RolesState {}

class RolesLoaded extends RolesState {
  final List<Role> roles;
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final String? searchQuery;
  final RoleType? filterType;
  final RoleStatus? filterStatus;

  RolesLoaded({
    required this.roles,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    this.searchQuery,
    this.filterType,
    this.filterStatus,
  });

  int get totalPages => pageSize > 0 ? (totalItems / pageSize).ceil() : 1;
}

class RolesError extends RolesState {
  final String message;
  RolesError(this.message);
}

// --- Bloc ---

class RolesBloc extends Bloc<RolesEvent, RolesState> {
  final GetRolesUseCase _getAll;

  int _currentPage = 1;
  int _pageSize = 20;
  RoleType? _filterType;
  RoleStatus? _filterStatus;

  RolesBloc({required GetRolesUseCase getAll})
      : _getAll = getAll,
        super(RolesInitial()) {
    on<LoadRolesEvent>(_onLoad);
    on<ChangeRolesPageEvent>(_onChangePage);
  }

  Future<void> _onLoad(
    LoadRolesEvent event,
    Emitter<RolesState> emit,
  ) async {
    emit(RolesLoading());
    _currentPage = event.page;
    _pageSize = event.pageSize;
    _filterType = event.type;
    _filterStatus = event.status;

    try {
      final result = await _getAll.execute(
        _currentPage,
        _pageSize,
        type: _filterType,
        name: event.searchQuery,
        status: _filterStatus,
      );
      emit(RolesLoaded(
        roles: result.items,
        currentPage: result.page,
        pageSize: result.pageSize,
        totalItems: result.totalCount,
        searchQuery: event.searchQuery,
        filterType: _filterType,
        filterStatus: _filterStatus,
      ));
    } catch (e) {
      emit(RolesError('Error al cargar roles: $e'));
    }
  }

  Future<void> _onChangePage(
    ChangeRolesPageEvent event,
    Emitter<RolesState> emit,
  ) async {
    add(LoadRolesEvent(
      page: event.page,
      pageSize: _pageSize,
      type: _filterType,
      status: _filterStatus,
    ));
  }
}
