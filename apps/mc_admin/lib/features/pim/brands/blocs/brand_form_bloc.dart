import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class BrandFormEvent {}

class SubmitCreateBrandEvent extends BrandFormEvent {
  final CreateBrandParams params;
  SubmitCreateBrandEvent(this.params);
}

class SubmitUpdateBrandEvent extends BrandFormEvent {
  final String id;
  final UpdateBrandParams params;
  SubmitUpdateBrandEvent({required this.id, required this.params});
}

class DeleteBrandFormEvent extends BrandFormEvent {
  final String id;
  DeleteBrandFormEvent(this.id);
}

class VerifyBrandFormEvent extends BrandFormEvent {
  final String id;
  VerifyBrandFormEvent(this.id);
}

class UnverifyBrandFormEvent extends BrandFormEvent {
  final String id;
  UnverifyBrandFormEvent(this.id);
}

class ValidateBrandNameEvent extends BrandFormEvent {
  final String name;
  final String? excludeId;
  ValidateBrandNameEvent(this.name, {this.excludeId});
}

// --- States ---

abstract class BrandFormState {}

class BrandFormInitial extends BrandFormState {}

class BrandFormSubmitting extends BrandFormState {}

class BrandFormSuccess extends BrandFormState {
  final MarketplaceBrand? entity;
  BrandFormSuccess({this.entity});
}

class BrandFormDeleted extends BrandFormState {}

class BrandFormError extends BrandFormState {
  final String message;
  BrandFormError(this.message);
}

class BrandFormNameValidated extends BrandFormState {
  final bool isConflict;
  BrandFormNameValidated({required this.isConflict});
}

// --- Bloc ---

class BrandFormBloc extends Bloc<BrandFormEvent, BrandFormState> {
  final CreateBrandUseCase _create;
  final UpdateBrandUseCase _update;
  final DeleteBrandUseCase _delete;
  final VerifyBrandUseCase _verify;
  final UnverifyBrandUseCase _unverify;
  final ValidateBrandNameUseCase? _validateName;

  BrandFormBloc({
    required CreateBrandUseCase create,
    required UpdateBrandUseCase update,
    required DeleteBrandUseCase delete,
    required VerifyBrandUseCase verify,
    required UnverifyBrandUseCase unverify,
    ValidateBrandNameUseCase? validateName,
  })  : _create = create,
        _update = update,
        _delete = delete,
        _verify = verify,
        _unverify = unverify,
        _validateName = validateName,
        super(BrandFormInitial()) {
    on<SubmitCreateBrandEvent>(_onCreate);
    on<SubmitUpdateBrandEvent>(_onUpdate);
    on<DeleteBrandFormEvent>(_onDelete);
    on<VerifyBrandFormEvent>(_onVerify);
    on<UnverifyBrandFormEvent>(_onUnverify);
    on<ValidateBrandNameEvent>(_onValidateName);
  }

  Future<void> _onCreate(
    SubmitCreateBrandEvent event,
    Emitter<BrandFormState> emit,
  ) async {
    emit(BrandFormSubmitting());
    try {
      final entity = await _create.execute(event.params);
      emit(BrandFormSuccess(entity: entity));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(BrandFormError('Ya existe una marca con ese nombre'));
      } else {
        emit(BrandFormError('Error al crear marca: $e'));
      }
    } catch (e) {
      emit(BrandFormError('Error al crear marca: $e'));
    }
  }

  Future<void> _onUpdate(
    SubmitUpdateBrandEvent event,
    Emitter<BrandFormState> emit,
  ) async {
    emit(BrandFormSubmitting());
    try {
      final entity = await _update.execute(event.id, event.params);
      emit(BrandFormSuccess(entity: entity));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(BrandFormError('Ya existe una marca con ese nombre'));
      } else {
        emit(BrandFormError('Error al actualizar marca: $e'));
      }
    } catch (e) {
      emit(BrandFormError('Error al actualizar marca: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteBrandFormEvent event,
    Emitter<BrandFormState> emit,
  ) async {
    emit(BrandFormSubmitting());
    try {
      await _delete.execute(event.id);
      emit(BrandFormDeleted());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(BrandFormError(
            'No se puede eliminar: la marca tiene productos asociados'));
      } else {
        emit(BrandFormError('Error al eliminar marca: $e'));
      }
    } catch (e) {
      emit(BrandFormError('Error al eliminar marca: $e'));
    }
  }

  Future<void> _onVerify(
    VerifyBrandFormEvent event,
    Emitter<BrandFormState> emit,
  ) async {
    emit(BrandFormSubmitting());
    try {
      final entity = await _verify.execute(event.id);
      emit(BrandFormSuccess(entity: entity));
    } catch (e) {
      emit(BrandFormError('Error al verificar marca: $e'));
    }
  }

  Future<void> _onUnverify(
    UnverifyBrandFormEvent event,
    Emitter<BrandFormState> emit,
  ) async {
    emit(BrandFormSubmitting());
    try {
      final entity = await _unverify.execute(event.id);
      emit(BrandFormSuccess(entity: entity));
    } catch (e) {
      emit(BrandFormError('Error al desverificar marca: $e'));
    }
  }

  Future<void> _onValidateName(
    ValidateBrandNameEvent event,
    Emitter<BrandFormState> emit,
  ) async {
    final validator = _validateName;
    if (validator == null) return;
    try {
      final available =
          await validator.execute(event.name, excludeId: event.excludeId);
      emit(BrandFormNameValidated(isConflict: !available));
    } catch (_) {
      // Validación de nombre es best-effort; no bloquear el formulario
    }
  }
}
