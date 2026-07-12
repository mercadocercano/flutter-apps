import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/global_products_repository.dart';
import '../../domain/models/bulk_verify_result_model.dart';
import '../../domain/models/enrichment_result_model.dart';
import '../../domain/models/global_product_model.dart';

// ─── Events ────────────────────────────────────────────────────────────────

abstract class GlobalProductsEvent {}

class LoadGlobalProductsEvent extends GlobalProductsEvent {
  final String? search;
  final String? businessType;
  final bool? isVerified;
  final bool? hasImage;
  final int? minQuality;
  final int? maxQuality;
  final bool? massVerifiedOnly;
  final int page;

  LoadGlobalProductsEvent({
    this.search,
    this.businessType,
    this.isVerified,
    this.hasImage,
    this.minQuality,
    this.maxQuality,
    this.massVerifiedOnly,
    this.page = 1,
  });
}

class LoadGlobalProductDetailEvent extends GlobalProductsEvent {
  final String id;
  LoadGlobalProductDetailEvent(this.id);
}

class LoadBusinessTypesEvent extends GlobalProductsEvent {}

class ClearGlobalProductImageEvent extends GlobalProductsEvent {
  final String productId;
  ClearGlobalProductImageEvent(this.productId);
}

class RejectProductImageEvent extends GlobalProductsEvent {
  final String productId;
  RejectProductImageEvent(this.productId);
}

// Selección múltiple para enrichment / bulk verify
class ToggleProductSelectionEvent extends GlobalProductsEvent {
  final String productId;
  ToggleProductSelectionEvent(this.productId);
}

class SelectAllProductsEvent extends GlobalProductsEvent {
  /// IDs de los productos visibles en la página actual (máx 100)
  final List<String> productIds;
  SelectAllProductsEvent(this.productIds);
}

class ClearSelectionEvent extends GlobalProductsEvent {}

// Enrichment
class RunEnrichmentEvent extends GlobalProductsEvent {
  final List<String> productIds;
  final bool forceReprocess;

  RunEnrichmentEvent({
    required this.productIds,
    this.forceReprocess = false,
  });
}

class DismissEnrichmentResultEvent extends GlobalProductsEvent {}

// Verificación / desverificación en lote
class BulkVerifySelectedEvent extends GlobalProductsEvent {
  final List<String> productIds;
  final bool verify;

  BulkVerifySelectedEvent({
    required this.productIds,
    required this.verify,
  });
}

class DismissBulkVerifyResultEvent extends GlobalProductsEvent {}

// ─── States ────────────────────────────────────────────────────────────────

abstract class GlobalProductsState {}

class GlobalProductsInitial extends GlobalProductsState {}

class GlobalProductsLoading extends GlobalProductsState {}

class GlobalProductsLoaded extends GlobalProductsState {
  final GlobalProductsPage page;
  final String? activeSearch;
  final String? activeBusinessType;
  final bool? activeIsVerified;
  final bool? activeHasImage;
  final int? activeMinQuality;
  final int? activeMaxQuality;
  final bool? activeMassVerifiedOnly;
  final List<String> allBusinessTypes;
  final Set<String> selectedIds;

  GlobalProductsLoaded(
    this.page, {
    this.activeSearch,
    this.activeBusinessType,
    this.activeIsVerified,
    this.activeHasImage,
    this.activeMinQuality,
    this.activeMaxQuality,
    this.activeMassVerifiedOnly,
    this.allBusinessTypes = const [],
    this.selectedIds = const {},
  });

  bool get hasSelection => selectedIds.isNotEmpty;

  GlobalProductsLoaded withSelection(Set<String> newSelected) {
    return GlobalProductsLoaded(
      page,
      activeSearch: activeSearch,
      activeBusinessType: activeBusinessType,
      activeIsVerified: activeIsVerified,
      activeHasImage: activeHasImage,
      activeMinQuality: activeMinQuality,
      activeMaxQuality: activeMaxQuality,
      activeMassVerifiedOnly: activeMassVerifiedOnly,
      allBusinessTypes: allBusinessTypes,
      selectedIds: newSelected,
    );
  }

  GlobalProductsLoaded withClearedSelection() => withSelection(const {});
}

class GlobalProductDetailLoaded extends GlobalProductsState {
  final GlobalProduct product;
  GlobalProductDetailLoaded(this.product);
}

class GlobalProductsError extends GlobalProductsState {
  final String message;
  GlobalProductsError(this.message);
}

class RejectImageSuccess extends GlobalProductsState {
  final String productId;
  RejectImageSuccess(this.productId);
}

class RejectImageError extends GlobalProductsState {
  final String message;
  RejectImageError(this.message);
}

class EnrichmentRunning extends GlobalProductsState {}

class EnrichmentSuccess extends GlobalProductsState {
  final EnrichmentResult result;
  /// IDs procesados (para poder refrescar la lista después)
  final List<String> processedIds;

  EnrichmentSuccess({required this.result, required this.processedIds});
}

class EnrichmentError extends GlobalProductsState {
  final String message;
  EnrichmentError(this.message);
}

class BulkVerifyRunning extends GlobalProductsState {}

class BulkVerifySuccess extends GlobalProductsState {
  final BulkVerifyResult result;
  final bool verify;

  BulkVerifySuccess({required this.result, required this.verify});
}

class BulkVerifyError extends GlobalProductsState {
  final String message;
  BulkVerifyError(this.message);
}

// ─── BLoC ──────────────────────────────────────────────────────────────────

class GlobalProductsBloc
    extends Bloc<GlobalProductsEvent, GlobalProductsState> {
  final GlobalProductsRepository _repository;

  List<String> _businessTypes = [];

  /// Última carga exitosa: la mantenemos para poder restaurar estado
  /// después del enrichment / bulk verify sin recargar la pantalla.
  GlobalProductsLoaded? _lastLoaded;

  GlobalProductsBloc({required GlobalProductsRepository repository})
      : _repository = repository,
        super(GlobalProductsInitial()) {
    on<LoadGlobalProductsEvent>(_onLoadList);
    on<LoadGlobalProductDetailEvent>(_onLoadDetail);
    on<LoadBusinessTypesEvent>(_onLoadBusinessTypes);
    on<ClearGlobalProductImageEvent>(_onClearImage);
    on<ToggleProductSelectionEvent>(_onToggleSelection);
    on<SelectAllProductsEvent>(_onSelectAll);
    on<ClearSelectionEvent>(_onClearSelection);
    on<RunEnrichmentEvent>(_onRunEnrichment);
    on<DismissEnrichmentResultEvent>(_onDismissResult);
    on<RejectProductImageEvent>(_onRejectImage);
    on<BulkVerifySelectedEvent>(_onBulkVerify);
    on<DismissBulkVerifyResultEvent>(_onDismissBulkVerifyResult);
  }

  Future<void> _onLoadBusinessTypes(
    LoadBusinessTypesEvent event,
    Emitter<GlobalProductsState> emit,
  ) async {
    try {
      _businessTypes = await _repository.getBusinessTypes();
    } catch (_) {
      // Non-fatal: el dropdown mostrará opciones vacías
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
        minQuality: event.minQuality,
        maxQuality: event.maxQuality,
        massVerifiedOnly: event.massVerifiedOnly,
        page: event.page,
      );
      final loaded = GlobalProductsLoaded(
        result,
        activeSearch: event.search,
        activeBusinessType: event.businessType,
        activeIsVerified: event.isVerified,
        activeHasImage: event.hasImage,
        activeMinQuality: event.minQuality,
        activeMaxQuality: event.maxQuality,
        activeMassVerifiedOnly: event.massVerifiedOnly,
        allBusinessTypes: _businessTypes,
      );
      _lastLoaded = loaded;
      emit(loaded);
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

  Future<void> _onClearImage(
    ClearGlobalProductImageEvent event,
    Emitter<GlobalProductsState> emit,
  ) async {
    emit(GlobalProductsLoading());
    try {
      await _repository.clearProductImage(event.productId);
      final product = await _repository.getById(event.productId);
      emit(GlobalProductDetailLoaded(product));
    } catch (e) {
      emit(GlobalProductsError('Error al eliminar la imagen: $e'));
    }
  }

  void _onToggleSelection(
    ToggleProductSelectionEvent event,
    Emitter<GlobalProductsState> emit,
  ) {
    final current = _lastLoaded;
    if (current == null) return;

    final newSelected = Set<String>.from(current.selectedIds);
    if (newSelected.contains(event.productId)) {
      newSelected.remove(event.productId);
    } else {
      newSelected.add(event.productId);
    }

    final updated = current.withSelection(newSelected);
    _lastLoaded = updated;
    emit(updated);
  }

  void _onSelectAll(
    SelectAllProductsEvent event,
    Emitter<GlobalProductsState> emit,
  ) {
    final current = _lastLoaded;
    if (current == null) return;

    // Si ya están todos seleccionados → deseleccionar todo
    final allSelected =
        event.productIds.every((id) => current.selectedIds.contains(id));

    final newSelected = allSelected
        ? const <String>{}
        : Set<String>.from(event.productIds.take(100));

    final updated = current.withSelection(newSelected);
    _lastLoaded = updated;
    emit(updated);
  }

  void _onClearSelection(
    ClearSelectionEvent event,
    Emitter<GlobalProductsState> emit,
  ) {
    final current = _lastLoaded;
    if (current == null) return;

    final updated = current.withSelection(const {});
    _lastLoaded = updated;
    emit(updated);
  }

  Future<void> _onRunEnrichment(
    RunEnrichmentEvent event,
    Emitter<GlobalProductsState> emit,
  ) async {
    emit(EnrichmentRunning());
    try {
      final result = await _repository.runEnrichment(
        productIds: event.productIds,
        forceReprocess: event.forceReprocess,
      );
      emit(EnrichmentSuccess(result: result, processedIds: event.productIds));
    } catch (e) {
      emit(EnrichmentError('Error al enriquecer productos: $e'));
    }
  }

  Future<void> _onRejectImage(
    RejectProductImageEvent event,
    Emitter<GlobalProductsState> emit,
  ) async {
    try {
      await _repository.rejectProductImage(event.productId);
      // Actualiza la lista local: pone imageUrl en null para el producto rechazado
      final current = _lastLoaded;
      if (current != null) {
        final updatedItems = current.page.items.map((p) {
          return p.id == event.productId ? p.copyWith(imageUrl: '') : p;
        }).toList();
        final updatedPage = GlobalProductsPage(
          items: updatedItems,
          totalCount: current.page.totalCount,
          page: current.page.page,
          pageSize: current.page.pageSize,
          totalPages: current.page.totalPages,
        );
        final updated = GlobalProductsLoaded(
          updatedPage,
          activeSearch: current.activeSearch,
          activeBusinessType: current.activeBusinessType,
          activeIsVerified: current.activeIsVerified,
          activeHasImage: current.activeHasImage,
          activeMinQuality: current.activeMinQuality,
          activeMaxQuality: current.activeMaxQuality,
          activeMassVerifiedOnly: current.activeMassVerifiedOnly,
          allBusinessTypes: current.allBusinessTypes,
          selectedIds: current.selectedIds,
        );
        _lastLoaded = updated;
        emit(RejectImageSuccess(event.productId));
        emit(updated);
      } else {
        emit(RejectImageSuccess(event.productId));
      }
    } catch (e) {
      emit(RejectImageError('Error al rechazar la imagen: $e'));
    }
  }

  void _onDismissResult(
    DismissEnrichmentResultEvent event,
    Emitter<GlobalProductsState> emit,
  ) {
    // Restaurar lista sin selección y recargar para reflejar nuevas imágenes
    final current = _lastLoaded;
    if (current != null) {
      final fresh = current.withClearedSelection();
      _lastLoaded = fresh;
      emit(fresh);
      // Recargar la lista para reflejar cambios de enrichment
      add(LoadGlobalProductsEvent(
        search: current.activeSearch,
        businessType: current.activeBusinessType,
        isVerified: current.activeIsVerified,
        hasImage: current.activeHasImage,
        minQuality: current.activeMinQuality,
        maxQuality: current.activeMaxQuality,
        massVerifiedOnly: current.activeMassVerifiedOnly,
      ));
    } else {
      add(LoadGlobalProductsEvent());
    }
  }

  Future<void> _onBulkVerify(
    BulkVerifySelectedEvent event,
    Emitter<GlobalProductsState> emit,
  ) async {
    emit(BulkVerifyRunning());
    try {
      final result = await _repository.bulkVerify(
        ids: event.productIds,
        verify: event.verify,
      );
      emit(BulkVerifySuccess(result: result, verify: event.verify));
    } catch (e) {
      emit(BulkVerifyError('Error al verificar productos: $e'));
    }
  }

  void _onDismissBulkVerifyResult(
    DismissBulkVerifyResultEvent event,
    Emitter<GlobalProductsState> emit,
  ) {
    final current = _lastLoaded;
    if (current != null) {
      final fresh = current.withClearedSelection();
      _lastLoaded = fresh;
      emit(fresh);
      // Refrescar listado para reflejar cambios de verificación
      add(LoadGlobalProductsEvent(
        search: current.activeSearch,
        businessType: current.activeBusinessType,
        isVerified: current.activeIsVerified,
        hasImage: current.activeHasImage,
        minQuality: current.activeMinQuality,
        maxQuality: current.activeMaxQuality,
        massVerifiedOnly: current.activeMassVerifiedOnly,
      ));
    } else {
      add(LoadGlobalProductsEvent());
    }
  }
}
