import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class WebProductsEvent {}

class LoadWebProductsEvent extends WebProductsEvent {
  final String? sourceId;
  final String? businessTypeId;

  LoadWebProductsEvent({this.sourceId, this.businessTypeId});
}

class SelectProductEvent extends WebProductsEvent {
  final String id;
  SelectProductEvent(this.id);
}

class DeselectProductEvent extends WebProductsEvent {
  final String id;
  DeselectProductEvent(this.id);
}

class SelectAllProductsEvent extends WebProductsEvent {}

class DeselectAllProductsEvent extends WebProductsEvent {}

class DeleteWebProductEvent extends WebProductsEvent {
  final String id;
  DeleteWebProductEvent(this.id);
}

class BulkDeleteWebProductsEvent extends WebProductsEvent {}

class AssignBusinessTypeEvent extends WebProductsEvent {
  final String id;
  final String businessTypeId;

  AssignBusinessTypeEvent({
    required this.id,
    required this.businessTypeId,
  });
}

class BulkAssignBusinessTypeEvent extends WebProductsEvent {
  final String businessTypeId;
  BulkAssignBusinessTypeEvent(this.businessTypeId);
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class WebProductsState {}

class WebProductsInitial extends WebProductsState {}

class WebProductsLoading extends WebProductsState {}

class WebProductsLoaded extends WebProductsState {
  final List<WebProduct> products;
  final Set<String> selectedIds;
  final String? sourceIdFilter;
  final String? businessTypeIdFilter;

  WebProductsLoaded({
    required this.products,
    required this.selectedIds,
    this.sourceIdFilter,
    this.businessTypeIdFilter,
  });

  bool get hasSelection => selectedIds.isNotEmpty;
  bool get allSelected =>
      products.isNotEmpty && selectedIds.length == products.length;

  WebProductsLoaded copyWith({
    List<WebProduct>? products,
    Set<String>? selectedIds,
    String? sourceIdFilter,
    String? businessTypeIdFilter,
  }) {
    return WebProductsLoaded(
      products: products ?? this.products,
      selectedIds: selectedIds ?? this.selectedIds,
      sourceIdFilter: sourceIdFilter ?? this.sourceIdFilter,
      businessTypeIdFilter: businessTypeIdFilter ?? this.businessTypeIdFilter,
    );
  }
}

class WebProductsError extends WebProductsState {
  final String message;
  WebProductsError(this.message);
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class WebProductsBloc extends Bloc<WebProductsEvent, WebProductsState> {
  final ListWebProductsUseCase _list;
  final DeleteWebProductUseCase _delete;
  final BulkDeleteWebProductsUseCase _bulkDelete;
  final AssignBusinessTypeUseCase _assign;
  final BulkAssignBusinessTypeUseCase _bulkAssign;

  String? _currentSourceId;
  String? _currentBusinessTypeId;

  WebProductsBloc({
    required ListWebProductsUseCase list,
    required DeleteWebProductUseCase delete,
    required BulkDeleteWebProductsUseCase bulkDelete,
    required AssignBusinessTypeUseCase assign,
    required BulkAssignBusinessTypeUseCase bulkAssign,
  })  : _list = list,
        _delete = delete,
        _bulkDelete = bulkDelete,
        _assign = assign,
        _bulkAssign = bulkAssign,
        super(WebProductsInitial()) {
    on<LoadWebProductsEvent>(_onLoad);
    on<SelectProductEvent>(_onSelect);
    on<DeselectProductEvent>(_onDeselect);
    on<SelectAllProductsEvent>(_onSelectAll);
    on<DeselectAllProductsEvent>(_onDeselectAll);
    on<DeleteWebProductEvent>(_onDelete);
    on<BulkDeleteWebProductsEvent>(_onBulkDelete);
    on<AssignBusinessTypeEvent>(_onAssign);
    on<BulkAssignBusinessTypeEvent>(_onBulkAssign);
  }

  Future<void> _onLoad(
    LoadWebProductsEvent event,
    Emitter<WebProductsState> emit,
  ) async {
    emit(WebProductsLoading());
    _currentSourceId = event.sourceId;
    _currentBusinessTypeId = event.businessTypeId;

    try {
      final page = await _list.execute(
        sourceId: event.sourceId,
        businessTypeId: event.businessTypeId,
      );
      emit(WebProductsLoaded(
        products: page.items,
        selectedIds: const {},
        sourceIdFilter: event.sourceId,
        businessTypeIdFilter: event.businessTypeId,
      ));
    } catch (e) {
      emit(WebProductsError('Error al cargar productos: $e'));
    }
  }

  void _onSelect(
    SelectProductEvent event,
    Emitter<WebProductsState> emit,
  ) {
    final current = _requireLoaded();
    if (current == null) return;
    emit(current.copyWith(
      selectedIds: {...current.selectedIds, event.id},
    ));
  }

  void _onDeselect(
    DeselectProductEvent event,
    Emitter<WebProductsState> emit,
  ) {
    final current = _requireLoaded();
    if (current == null) return;
    emit(current.copyWith(
      selectedIds: current.selectedIds.difference({event.id}),
    ));
  }

  void _onSelectAll(
    SelectAllProductsEvent event,
    Emitter<WebProductsState> emit,
  ) {
    final current = _requireLoaded();
    if (current == null) return;
    emit(current.copyWith(
      selectedIds: current.products.map((p) => p.id).toSet(),
    ));
  }

  void _onDeselectAll(
    DeselectAllProductsEvent event,
    Emitter<WebProductsState> emit,
  ) {
    final current = _requireLoaded();
    if (current == null) return;
    emit(current.copyWith(selectedIds: const {}));
  }

  Future<void> _onDelete(
    DeleteWebProductEvent event,
    Emitter<WebProductsState> emit,
  ) async {
    try {
      await _delete.execute(event.id);
      await _reload(emit);
    } on DioException catch (e) {
      emit(WebProductsError('Error al eliminar producto: ${e.message}'));
    } catch (e) {
      emit(WebProductsError('Error al eliminar producto: $e'));
    }
  }

  Future<void> _onBulkDelete(
    BulkDeleteWebProductsEvent event,
    Emitter<WebProductsState> emit,
  ) async {
    final current = _requireLoaded();
    if (current == null || !current.hasSelection) return;

    try {
      await _bulkDelete.execute(current.selectedIds.toList());
      await _reload(emit);
    } catch (e) {
      emit(WebProductsError('Error al eliminar productos: $e'));
    }
  }

  Future<void> _onAssign(
    AssignBusinessTypeEvent event,
    Emitter<WebProductsState> emit,
  ) async {
    try {
      await _assign.execute(event.id, event.businessTypeId);
      await _reload(emit);
    } catch (e) {
      emit(WebProductsError('Error al asignar tipo de comercio: $e'));
    }
  }

  Future<void> _onBulkAssign(
    BulkAssignBusinessTypeEvent event,
    Emitter<WebProductsState> emit,
  ) async {
    final current = _requireLoaded();
    if (current == null || !current.hasSelection) return;

    try {
      await _bulkAssign.execute(
        current.selectedIds.toList(),
        event.businessTypeId,
      );
      await _reload(emit);
    } catch (e) {
      emit(WebProductsError('Error al asignar tipo de comercio en bulk: $e'));
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  WebProductsLoaded? _requireLoaded() {
    final current = state;
    if (current is WebProductsLoaded) return current;
    return null;
  }

  Future<void> _reload(Emitter<WebProductsState> emit) async {
    final page = await _list.execute(
      sourceId: _currentSourceId,
      businessTypeId: _currentBusinessTypeId,
    );
    emit(WebProductsLoaded(
      products: page.items,
      selectedIds: const {},
      sourceIdFilter: _currentSourceId,
      businessTypeIdFilter: _currentBusinessTypeId,
    ));
  }
}
