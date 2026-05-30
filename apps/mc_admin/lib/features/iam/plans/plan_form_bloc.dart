import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class PlanFormEvent {}

class SubmitCreatePlanEvent extends PlanFormEvent {
  final UpsertPlanParams params;
  SubmitCreatePlanEvent(this.params);
}

class SubmitUpdatePlanEvent extends PlanFormEvent {
  final String id;
  final UpsertPlanParams params;
  SubmitUpdatePlanEvent({required this.id, required this.params});
}

class DeletePlanFormEvent extends PlanFormEvent {
  final String id;
  DeletePlanFormEvent(this.id);
}

// --- States ---

abstract class PlanFormState {}

class PlanFormInitial extends PlanFormState {}

class PlanFormSubmitting extends PlanFormState {}

class PlanFormSuccess extends PlanFormState {
  final Plan? entity;
  PlanFormSuccess({this.entity});
}

class PlanFormDeleted extends PlanFormState {}

class PlanFormError extends PlanFormState {
  final String message;
  PlanFormError(this.message);
}

// --- Bloc ---

class PlanFormBloc extends Bloc<PlanFormEvent, PlanFormState> {
  final CreatePlanUseCase _create;
  final UpdatePlanUseCase _update;
  final DeletePlanUseCase _delete;

  PlanFormBloc({
    required CreatePlanUseCase create,
    required UpdatePlanUseCase update,
    required DeletePlanUseCase delete,
  })  : _create = create,
        _update = update,
        _delete = delete,
        super(PlanFormInitial()) {
    on<SubmitCreatePlanEvent>(_onCreate);
    on<SubmitUpdatePlanEvent>(_onUpdate);
    on<DeletePlanFormEvent>(_onDelete);
  }

  Future<void> _onCreate(
    SubmitCreatePlanEvent event,
    Emitter<PlanFormState> emit,
  ) async {
    emit(PlanFormSubmitting());
    try {
      final entity = await _create.execute(event.params);
      emit(PlanFormSuccess(entity: entity));
    } catch (e) {
      emit(PlanFormError('Error al crear plan: $e'));
    }
  }

  Future<void> _onUpdate(
    SubmitUpdatePlanEvent event,
    Emitter<PlanFormState> emit,
  ) async {
    emit(PlanFormSubmitting());
    try {
      final entity = await _update.execute(event.id, event.params);
      emit(PlanFormSuccess(entity: entity));
    } catch (e) {
      emit(PlanFormError('Error al actualizar plan: $e'));
    }
  }

  Future<void> _onDelete(
    DeletePlanFormEvent event,
    Emitter<PlanFormState> emit,
  ) async {
    emit(PlanFormSubmitting());
    try {
      await _delete.execute(event.id);
      emit(PlanFormDeleted());
    } catch (e) {
      emit(PlanFormError('Error al eliminar plan: $e'));
    }
  }
}
