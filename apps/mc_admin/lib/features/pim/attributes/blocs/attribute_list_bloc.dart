import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class AttributeListEvent {}

class LoadAttributesEvent extends AttributeListEvent {
  final int page;
  final int pageSize;
  final String? search;
  final AttributeType? type;

  LoadAttributesEvent({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.type,
  });
}

class RefreshAttributesEvent extends AttributeListEvent {}

class DeleteAttributeEvent extends AttributeListEvent {
  final String id;
  DeleteAttributeEvent(this.id);
}

// --- States ---

abstract class AttributeListState {}

class AttributeListInitial extends AttributeListState {}

class AttributeListLoading extends AttributeListState {}

class AttributeListLoaded extends AttributeListState {
  final List<MarketplaceAttribute> attributes;
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final String? filterSearch;
  final AttributeType? filterType;

  AttributeListLoaded({
    required this.attributes,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    this.filterSearch,
    this.filterType,
  });

  int get totalPages => pageSize > 0 ? (totalItems / pageSize).ceil() : 1;
}

class AttributeListError extends AttributeListState {
  final String message;
  AttributeListError(this.message);
}

// --- Bloc ---

class AttributeListBloc
    extends Bloc<AttributeListEvent, AttributeListState> {
  final ListMarketplaceAttributesUseCase _list;
  final DeleteMarketplaceAttributeUseCase _delete;

  int _currentPage = 1;
  int _pageSize = 20;
  String? _search;
  AttributeType? _type;

  AttributeListBloc({
    required ListMarketplaceAttributesUseCase list,
    required DeleteMarketplaceAttributeUseCase delete,
  })  : _list = list,
        _delete = delete,
        super(AttributeListInitial()) {
    on<LoadAttributesEvent>(_onLoad);
    on<RefreshAttributesEvent>(_onRefresh);
    on<DeleteAttributeEvent>(_onDelete);
  }

  Future<void> _onLoad(
    LoadAttributesEvent event,
    Emitter<AttributeListState> emit,
  ) async {
    emit(AttributeListLoading());
    _currentPage = event.page;
    _pageSize = event.pageSize;
    _search = event.search;
    _type = event.type;

    try {
      final result = await _list.execute(
        _currentPage,
        _pageSize,
        search: _search,
        type: _type,
      );
      emit(AttributeListLoaded(
        attributes: result.items,
        currentPage: result.page,
        pageSize: result.pageSize,
        totalItems: result.totalCount,
        filterSearch: _search,
        filterType: _type,
      ));
    } catch (e) {
      emit(AttributeListError('Error al cargar atributos: $e'));
    }
  }

  Future<void> _onRefresh(
    RefreshAttributesEvent event,
    Emitter<AttributeListState> emit,
  ) async {
    add(LoadAttributesEvent(
      page: _currentPage,
      pageSize: _pageSize,
      search: _search,
      type: _type,
    ));
  }

  Future<void> _onDelete(
    DeleteAttributeEvent event,
    Emitter<AttributeListState> emit,
  ) async {
    try {
      await _delete.execute(event.id);
      add(RefreshAttributesEvent());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(AttributeListError(
            'Atributo en uso, no se puede eliminar'));
      } else {
        emit(AttributeListError('Error al eliminar atributo: $e'));
      }
    } catch (e) {
      emit(AttributeListError('Error al eliminar atributo: $e'));
    }
  }
}
