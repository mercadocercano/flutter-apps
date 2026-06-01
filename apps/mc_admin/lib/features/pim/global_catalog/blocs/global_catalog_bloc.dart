import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class GlobalCatalogEvent {}

class LoadGlobalCatalogEvent extends GlobalCatalogEvent {
  final int page;
  final int pageSize;
  final String? search;
  final String? businessTypeId;
  final bool? isVerified;

  LoadGlobalCatalogEvent({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.businessTypeId,
    this.isVerified,
  });
}

class ChangeGlobalCatalogPageEvent extends GlobalCatalogEvent {
  final int page;
  ChangeGlobalCatalogPageEvent(this.page);
}

class RefreshGlobalCatalogEvent extends GlobalCatalogEvent {}

// --- States ---

abstract class GlobalCatalogState {}

class GlobalCatalogInitial extends GlobalCatalogState {}

class GlobalCatalogLoading extends GlobalCatalogState {}

class GlobalCatalogLoaded extends GlobalCatalogState {
  final List<GlobalProduct> products;
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final String? filterSearch;
  final String? filterBusinessTypeId;
  final bool? filterIsVerified;

  GlobalCatalogLoaded({
    required this.products,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    this.filterSearch,
    this.filterBusinessTypeId,
    this.filterIsVerified,
  });

  int get totalPages => pageSize > 0 ? (totalItems / pageSize).ceil() : 1;
}

class GlobalCatalogError extends GlobalCatalogState {
  final String message;
  GlobalCatalogError(this.message);
}

// --- Bloc ---

class GlobalCatalogBloc extends Bloc<GlobalCatalogEvent, GlobalCatalogState> {
  final ListGlobalProductsUseCase _list;

  int _currentPage = 1;
  int _pageSize = 20;
  String? _search;
  String? _businessTypeId;
  bool? _isVerified;

  GlobalCatalogBloc({required ListGlobalProductsUseCase list})
      : _list = list,
        super(GlobalCatalogInitial()) {
    on<LoadGlobalCatalogEvent>(_onLoad);
    on<ChangeGlobalCatalogPageEvent>(_onChangePage);
    on<RefreshGlobalCatalogEvent>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadGlobalCatalogEvent event,
    Emitter<GlobalCatalogState> emit,
  ) async {
    emit(GlobalCatalogLoading());
    _currentPage = event.page;
    _pageSize = event.pageSize;
    _search = event.search;
    _businessTypeId = event.businessTypeId;
    _isVerified = event.isVerified;

    try {
      final result = await _list.execute(
        _currentPage,
        _pageSize,
        search: _search,
        businessTypeId: _businessTypeId,
        isVerified: _isVerified,
      );
      emit(GlobalCatalogLoaded(
        products: result.items,
        currentPage: result.page,
        pageSize: result.pageSize,
        totalItems: result.totalCount,
        filterSearch: _search,
        filterBusinessTypeId: _businessTypeId,
        filterIsVerified: _isVerified,
      ));
    } catch (e) {
      emit(GlobalCatalogError('Error al cargar catálogo global: $e'));
    }
  }

  Future<void> _onChangePage(
    ChangeGlobalCatalogPageEvent event,
    Emitter<GlobalCatalogState> emit,
  ) async {
    add(LoadGlobalCatalogEvent(
      page: event.page,
      pageSize: _pageSize,
      search: _search,
      businessTypeId: _businessTypeId,
      isVerified: _isVerified,
    ));
  }

  Future<void> _onRefresh(
    RefreshGlobalCatalogEvent event,
    Emitter<GlobalCatalogState> emit,
  ) async {
    add(LoadGlobalCatalogEvent(
      page: _currentPage,
      pageSize: _pageSize,
      search: _search,
      businessTypeId: _businessTypeId,
      isVerified: _isVerified,
    ));
  }
}
