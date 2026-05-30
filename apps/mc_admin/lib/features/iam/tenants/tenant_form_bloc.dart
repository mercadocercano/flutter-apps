import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class TenantFormEvent {}

class SubmitCreateTenantEvent extends TenantFormEvent {
  final CreateTenantParams params;
  SubmitCreateTenantEvent(this.params);
}

class SubmitUpdateTenantEvent extends TenantFormEvent {
  final String id;
  final UpdateTenantParams params;
  SubmitUpdateTenantEvent({required this.id, required this.params});
}

class DeleteTenantFormEvent extends TenantFormEvent {
  final String id;
  DeleteTenantFormEvent(this.id);
}

// --- States ---

abstract class TenantFormState {}

class TenantFormInitial extends TenantFormState {}

class TenantFormSubmitting extends TenantFormState {}

class TenantFormSuccess extends TenantFormState {
  final Tenant? entity;
  TenantFormSuccess({this.entity});
}

class TenantFormDeleted extends TenantFormState {}

class TenantFormError extends TenantFormState {
  final String message;
  TenantFormError(this.message);
}

// --- Bloc ---

class TenantFormBloc extends Bloc<TenantFormEvent, TenantFormState> {
  final CreateTenantUseCase _create;
  final UpdateTenantUseCase _update;
  final DeleteTenantUseCase _delete;

  TenantFormBloc({
    required CreateTenantUseCase create,
    required UpdateTenantUseCase update,
    required DeleteTenantUseCase delete,
  })  : _create = create,
        _update = update,
        _delete = delete,
        super(TenantFormInitial()) {
    on<SubmitCreateTenantEvent>(_onCreate);
    on<SubmitUpdateTenantEvent>(_onUpdate);
    on<DeleteTenantFormEvent>(_onDelete);
  }

  Future<void> _onCreate(
    SubmitCreateTenantEvent event,
    Emitter<TenantFormState> emit,
  ) async {
    emit(TenantFormSubmitting());
    try {
      final entity = await _create.execute(event.params);
      emit(TenantFormSuccess(entity: entity));
    } catch (e) {
      emit(TenantFormError('Error al crear tenant: $e'));
    }
  }

  Future<void> _onUpdate(
    SubmitUpdateTenantEvent event,
    Emitter<TenantFormState> emit,
  ) async {
    emit(TenantFormSubmitting());
    try {
      final entity = await _update.execute(event.id, event.params);
      emit(TenantFormSuccess(entity: entity));
    } catch (e) {
      emit(TenantFormError('Error al actualizar tenant: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteTenantFormEvent event,
    Emitter<TenantFormState> emit,
  ) async {
    emit(TenantFormSubmitting());
    try {
      await _delete.execute(event.id);
      emit(TenantFormDeleted());
    } catch (e) {
      emit(TenantFormError('Error al eliminar tenant: $e'));
    }
  }
}
