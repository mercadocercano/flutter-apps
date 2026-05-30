import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class PlansEvent {}

class LoadPlansEvent extends PlansEvent {
  final int page;
  final int pageSize;
  final String? searchQuery;
  final PlanType? type;
  final PlanStatus? status;

  LoadPlansEvent({
    this.page = 1,
    this.pageSize = 20,
    this.searchQuery,
    this.type,
    this.status,
  });
}

class ChangePlansPageEvent extends PlansEvent {
  final int page;
  ChangePlansPageEvent(this.page);
}

// --- States ---

abstract class PlansState {}

class PlansInitial extends PlansState {}

class PlansLoading extends PlansState {}

class PlansLoaded extends PlansState {
  final List<Plan> plans;
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final String? searchQuery;
  final PlanType? filterType;
  final PlanStatus? filterStatus;

  PlansLoaded({
    required this.plans,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    this.searchQuery,
    this.filterType,
    this.filterStatus,
  });

  int get totalPages => pageSize > 0 ? (totalItems / pageSize).ceil() : 1;
}

class PlansError extends PlansState {
  final String message;
  PlansError(this.message);
}

// --- Bloc ---

class PlansBloc extends Bloc<PlansEvent, PlansState> {
  final GetPlansUseCase _getAll;

  int _currentPage = 1;
  int _pageSize = 20;
  PlanType? _filterType;
  PlanStatus? _filterStatus;

  PlansBloc({required GetPlansUseCase getAll})
      : _getAll = getAll,
        super(PlansInitial()) {
    on<LoadPlansEvent>(_onLoad);
    on<ChangePlansPageEvent>(_onChangePage);
  }

  Future<void> _onLoad(
    LoadPlansEvent event,
    Emitter<PlansState> emit,
  ) async {
    emit(PlansLoading());
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
      emit(PlansLoaded(
        plans: result.items,
        currentPage: result.page,
        pageSize: result.pageSize,
        totalItems: result.totalCount,
        searchQuery: event.searchQuery,
        filterType: _filterType,
        filterStatus: _filterStatus,
      ));
    } catch (e) {
      emit(PlansError('Error al cargar planes: $e'));
    }
  }

  Future<void> _onChangePage(
    ChangePlansPageEvent event,
    Emitter<PlansState> emit,
  ) async {
    add(LoadPlansEvent(
      page: event.page,
      pageSize: _pageSize,
      type: _filterType,
      status: _filterStatus,
    ));
  }
}
