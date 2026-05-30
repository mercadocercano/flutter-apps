import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class RoleFormEvent {}

class SubmitCreateRoleEvent extends RoleFormEvent {
  final UpsertRoleParams params;
  SubmitCreateRoleEvent(this.params);
}

class SubmitUpdateRoleEvent extends RoleFormEvent {
  final String id;
  final UpsertRoleParams params;
  SubmitUpdateRoleEvent({required this.id, required this.params});
}

class DeleteRoleFormEvent extends RoleFormEvent {
  final String id;
  DeleteRoleFormEvent(this.id);
}

// --- States ---

abstract class RoleFormState {}

class RoleFormInitial extends RoleFormState {}

class RoleFormSubmitting extends RoleFormState {}

class RoleFormSuccess extends RoleFormState {
  final Role? entity;
  RoleFormSuccess({this.entity});
}

class RoleFormDeleted extends RoleFormState {}

class RoleFormError extends RoleFormState {
  final String message;
  RoleFormError(this.message);
}

// --- Bloc ---

class RoleFormBloc extends Bloc<RoleFormEvent, RoleFormState> {
  final CreateRoleUseCase _create;
  final UpdateRoleUseCase _update;
  final DeleteRoleUseCase _delete;

  RoleFormBloc({
    required CreateRoleUseCase create,
    required UpdateRoleUseCase update,
    required DeleteRoleUseCase delete,
  })  : _create = create,
        _update = update,
        _delete = delete,
        super(RoleFormInitial()) {
    on<SubmitCreateRoleEvent>(_onCreate);
    on<SubmitUpdateRoleEvent>(_onUpdate);
    on<DeleteRoleFormEvent>(_onDelete);
  }

  Future<void> _onCreate(
    SubmitCreateRoleEvent event,
    Emitter<RoleFormState> emit,
  ) async {
    emit(RoleFormSubmitting());
    try {
      final entity = await _create.execute(event.params);
      emit(RoleFormSuccess(entity: entity));
    } catch (e) {
      emit(RoleFormError('Error al crear rol: $e'));
    }
  }

  Future<void> _onUpdate(
    SubmitUpdateRoleEvent event,
    Emitter<RoleFormState> emit,
  ) async {
    emit(RoleFormSubmitting());
    try {
      final entity = await _update.execute(event.id, event.params);
      emit(RoleFormSuccess(entity: entity));
    } catch (e) {
      emit(RoleFormError('Error al actualizar rol: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteRoleFormEvent event,
    Emitter<RoleFormState> emit,
  ) async {
    emit(RoleFormSubmitting());
    try {
      await _delete.execute(event.id);
      emit(RoleFormDeleted());
    } catch (e) {
      emit(RoleFormError('Error al eliminar rol: $e'));
    }
  }
}
