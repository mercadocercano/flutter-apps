import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class BrandsEvent {}

class LoadBrandsEvent extends BrandsEvent {
  final int page;
  final int pageSize;
  final String? searchQuery;
  final BrandVerificationStatus? verificationStatus;
  final bool? isActive;

  LoadBrandsEvent({
    this.page = 1,
    this.pageSize = 20,
    this.searchQuery,
    this.verificationStatus,
    this.isActive,
  });
}

class ChangeBrandsPageEvent extends BrandsEvent {
  final int page;
  ChangeBrandsPageEvent(this.page);
}

// --- States ---

abstract class BrandsState {}

class BrandsInitial extends BrandsState {}

class BrandsLoading extends BrandsState {}

class BrandsLoaded extends BrandsState {
  final List<MarketplaceBrand> brands;
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final String? searchQuery;
  final BrandVerificationStatus? filterVerificationStatus;
  final bool? filterIsActive;

  BrandsLoaded({
    required this.brands,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    this.searchQuery,
    this.filterVerificationStatus,
    this.filterIsActive,
  });

  int get totalPages => pageSize > 0 ? (totalItems / pageSize).ceil() : 1;
}

class BrandsError extends BrandsState {
  final String message;
  BrandsError(this.message);
}

// --- Bloc ---

class BrandsBloc extends Bloc<BrandsEvent, BrandsState> {
  final GetBrandsUseCase _getAll;

  int _currentPage = 1;
  int _pageSize = 20;
  String? _searchQuery;
  BrandVerificationStatus? _filterVerificationStatus;
  bool? _filterIsActive;

  BrandsBloc({required GetBrandsUseCase getAll})
      : _getAll = getAll,
        super(BrandsInitial()) {
    on<LoadBrandsEvent>(_onLoad);
    on<ChangeBrandsPageEvent>(_onChangePage);
  }

  Future<void> _onLoad(
    LoadBrandsEvent event,
    Emitter<BrandsState> emit,
  ) async {
    emit(BrandsLoading());
    _currentPage = event.page;
    _pageSize = event.pageSize;
    _searchQuery = event.searchQuery;
    _filterVerificationStatus = event.verificationStatus;
    _filterIsActive = event.isActive;

    try {
      final result = await _getAll.execute(
        _currentPage,
        _pageSize,
        name: _searchQuery,
        verificationStatus: _filterVerificationStatus,
        isActive: _filterIsActive,
      );
      emit(BrandsLoaded(
        brands: result.items,
        currentPage: result.page,
        pageSize: result.pageSize,
        totalItems: result.totalCount,
        searchQuery: _searchQuery,
        filterVerificationStatus: _filterVerificationStatus,
        filterIsActive: _filterIsActive,
      ));
    } catch (e) {
      emit(BrandsError('Error al cargar marcas: $e'));
    }
  }

  Future<void> _onChangePage(
    ChangeBrandsPageEvent event,
    Emitter<BrandsState> emit,
  ) async {
    add(LoadBrandsEvent(
      page: event.page,
      pageSize: _pageSize,
      searchQuery: _searchQuery,
      verificationStatus: _filterVerificationStatus,
      isActive: _filterIsActive,
    ));
  }
}
