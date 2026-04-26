import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/global_products_repository.dart';
import '../../domain/models/global_product_model.dart';

// --- Events ---

abstract class GlobalProductsEvent {}

class LoadGlobalProductsEvent extends GlobalProductsEvent {
  final String? search;
  final String? businessType;
  final bool? isVerified;
  final bool? hasImage;
  final int page;

  LoadGlobalProductsEvent({
    this.search,
    this.businessType,
    this.isVerified,
    this.hasImage,
    this.page = 1,
  });
}

class LoadGlobalProductDetailEvent extends GlobalProductsEvent {
  final String id;
  LoadGlobalProductDetailEvent(this.id);
}

class LoadBusinessTypesEvent extends GlobalProductsEvent {}

// --- States ---

abstract class GlobalProductsState {}

class GlobalProductsInitial extends GlobalProductsState {}

class GlobalProductsLoading extends GlobalProductsState {}

class GlobalProductsLoaded extends GlobalProductsState {
  final GlobalProductsPage page;
  final String? activeSearch;
  final String? activeBusinessType;
  final bool? activeIsVerified;
  final bool? activeHasImage;
  final List<String> allBusinessTypes;

  GlobalProductsLoaded(
    this.page, {
    this.activeSearch,
    this.activeBusinessType,
    this.activeIsVerified,
    this.activeHasImage,
    this.allBusinessTypes = const [],
  });
}

class GlobalProductDetailLoaded extends GlobalProductsState {
  final GlobalProduct product;
  GlobalProductDetailLoaded(this.product);
}

class GlobalProductsError extends GlobalProductsState {
  final String message;
  GlobalProductsError(this.message);
}

// --- Bloc ---

class GlobalProductsBloc
    extends Bloc<GlobalProductsEvent, GlobalProductsState> {
  final GlobalProductsRepository _repository;

  List<String> _businessTypes = [];

  GlobalProductsBloc({required GlobalProductsRepository repository})
      : _repository = repository,
        super(GlobalProductsInitial()) {
    on<LoadGlobalProductsEvent>(_onLoadList);
    on<LoadGlobalProductDetailEvent>(_onLoadDetail);
    on<LoadBusinessTypesEvent>(_onLoadBusinessTypes);
  }

  Future<void> _onLoadBusinessTypes(
    LoadBusinessTypesEvent event,
    Emitter<GlobalProductsState> emit,
  ) async {
    try {
      _businessTypes = await _repository.getBusinessTypes();
    } catch (_) {
      // Non-fatal: dropdown will show empty
    }
  }

  Future<void> _onLoadList(
    LoadGlobalProductsEvent event,
    Emitter<GlobalProductsState> emit,
  ) async {
    emit(GlobalProductsLoading());
    try {
      final result = await _repository.getAll(
        search: event.search,
        businessType: event.businessType,
        isVerified: event.isVerified,
        hasImage: event.hasImage,
        page: event.page,
      );
      emit(GlobalProductsLoaded(
        result,
        activeSearch: event.search,
        activeBusinessType: event.businessType,
        activeIsVerified: event.isVerified,
        activeHasImage: event.hasImage,
        allBusinessTypes: _businessTypes,
      ));
    } catch (e) {
      emit(GlobalProductsError('Error al cargar productos globales: $e'));
    }
  }

  Future<void> _onLoadDetail(
    LoadGlobalProductDetailEvent event,
    Emitter<GlobalProductsState> emit,
  ) async {
    emit(GlobalProductsLoading());
    try {
      final product = await _repository.getById(event.id);
      emit(GlobalProductDetailLoaded(product));
    } catch (e) {
      emit(GlobalProductsError('Error al cargar el producto: $e'));
    }
  }
}
