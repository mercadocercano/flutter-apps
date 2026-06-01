import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class BusinessTypesEvent {}

class LoadBusinessTypesEvent extends BusinessTypesEvent {
  final bool? isActive;
  LoadBusinessTypesEvent({this.isActive});
}

class RefreshBusinessTypesEvent extends BusinessTypesEvent {}

class ActivateBusinessTypeEvent extends BusinessTypesEvent {
  final String id;
  ActivateBusinessTypeEvent(this.id);
}

class DeactivateBusinessTypeEvent extends BusinessTypesEvent {
  final String id;
  DeactivateBusinessTypeEvent(this.id);
}

class DeleteBusinessTypeEvent extends BusinessTypesEvent {
  final String id;
  DeleteBusinessTypeEvent(this.id);
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class BusinessTypesState {}

class BusinessTypesInitial extends BusinessTypesState {}

class BusinessTypesLoading extends BusinessTypesState {}

class BusinessTypesLoaded extends BusinessTypesState {
  final List<BusinessType> types;
  final bool? filterIsActive;

  BusinessTypesLoaded({
    required this.types,
    this.filterIsActive,
  });
}

class BusinessTypesError extends BusinessTypesState {
  final String message;
  BusinessTypesError(this.message);
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class BusinessTypesBloc
    extends Bloc<BusinessTypesEvent, BusinessTypesState> {
  final ListBusinessTypesUseCase _list;
  final ActivateBusinessTypeUseCase _activate;
  final DeactivateBusinessTypeUseCase _deactivate;
  final DeleteBusinessTypeUseCase _delete;

  bool? _filterIsActive;

  BusinessTypesBloc({
    required ListBusinessTypesUseCase list,
    required ActivateBusinessTypeUseCase activate,
    required DeactivateBusinessTypeUseCase deactivate,
    required DeleteBusinessTypeUseCase delete,
  })  : _list = list,
        _activate = activate,
        _deactivate = deactivate,
        _delete = delete,
        super(BusinessTypesInitial()) {
    on<LoadBusinessTypesEvent>(_onLoad);
    on<RefreshBusinessTypesEvent>(_onRefresh);
    on<ActivateBusinessTypeEvent>(_onActivate);
    on<DeactivateBusinessTypeEvent>(_onDeactivate);
    on<DeleteBusinessTypeEvent>(_onDelete);
  }

  Future<void> _onLoad(
    LoadBusinessTypesEvent event,
    Emitter<BusinessTypesState> emit,
  ) async {
    emit(BusinessTypesLoading());
    _filterIsActive = event.isActive;

    try {
      final result = await _list.execute(isActive: _filterIsActive);
      emit(BusinessTypesLoaded(
        types: result.items,
        filterIsActive: _filterIsActive,
      ));
    } catch (e) {
      emit(BusinessTypesError('Error al cargar tipos de negocio: $e'));
    }
  }

  Future<void> _onRefresh(
    RefreshBusinessTypesEvent event,
    Emitter<BusinessTypesState> emit,
  ) async {
    add(LoadBusinessTypesEvent(isActive: _filterIsActive));
  }

  Future<void> _onActivate(
    ActivateBusinessTypeEvent event,
    Emitter<BusinessTypesState> emit,
  ) async {
    try {
      await _activate.execute(event.id);
      add(RefreshBusinessTypesEvent());
    } on DioException catch (e) {
      emit(BusinessTypesError(
        'Error al activar tipo de negocio: ${e.message}',
      ));
    } catch (e) {
      emit(BusinessTypesError('Error al activar tipo de negocio: $e'));
    }
  }

  Future<void> _onDeactivate(
    DeactivateBusinessTypeEvent event,
    Emitter<BusinessTypesState> emit,
  ) async {
    try {
      await _deactivate.execute(event.id);
      add(RefreshBusinessTypesEvent());
    } on DioException catch (e) {
      emit(BusinessTypesError(
        'Error al desactivar tipo de negocio: ${e.message}',
      ));
    } catch (e) {
      emit(BusinessTypesError('Error al desactivar tipo de negocio: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteBusinessTypeEvent event,
    Emitter<BusinessTypesState> emit,
  ) async {
    try {
      await _delete.execute(event.id);
      add(RefreshBusinessTypesEvent());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(BusinessTypesError(
          'Tipo de negocio en uso, no se puede eliminar',
        ));
      } else {
        emit(BusinessTypesError(
          'Error al eliminar tipo de negocio: ${e.message}',
        ));
      }
    } catch (e) {
      emit(BusinessTypesError('Error al eliminar tipo de negocio: $e'));
    }
  }
}
