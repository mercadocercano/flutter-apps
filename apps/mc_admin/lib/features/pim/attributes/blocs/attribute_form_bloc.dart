import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class AttributeFormEvent {}

class LoadAttributeEvent extends AttributeFormEvent {
  final String id;
  LoadAttributeEvent(this.id);
}

class SubmitAttributeFormEvent extends AttributeFormEvent {
  final MarketplaceAttribute attribute;
  SubmitAttributeFormEvent(this.attribute);
}

class ResetAttributeFormEvent extends AttributeFormEvent {}

// --- States ---

abstract class AttributeFormState {}

class AttributeFormInitial extends AttributeFormState {}

class AttributeFormLoading extends AttributeFormState {}

class AttributeFormLoaded extends AttributeFormState {
  final MarketplaceAttribute attribute;
  AttributeFormLoaded(this.attribute);
}

class AttributeFormSubmitting extends AttributeFormState {}

class AttributeFormSuccess extends AttributeFormState {
  final MarketplaceAttribute attribute;
  AttributeFormSuccess(this.attribute);
}

class AttributeFormError extends AttributeFormState {
  final String message;
  AttributeFormError(this.message);
}

// --- Bloc ---

class AttributeFormBloc
    extends Bloc<AttributeFormEvent, AttributeFormState> {
  final GetMarketplaceAttributeUseCase _get;
  final CreateMarketplaceAttributeUseCase _create;
  final UpdateMarketplaceAttributeUseCase _update;

  AttributeFormBloc({
    required GetMarketplaceAttributeUseCase get,
    required CreateMarketplaceAttributeUseCase create,
    required UpdateMarketplaceAttributeUseCase update,
  })  : _get = get,
        _create = create,
        _update = update,
        super(AttributeFormInitial()) {
    on<LoadAttributeEvent>(_onLoad);
    on<SubmitAttributeFormEvent>(_onSubmit);
    on<ResetAttributeFormEvent>(_onReset);
  }

  Future<void> _onLoad(
    LoadAttributeEvent event,
    Emitter<AttributeFormState> emit,
  ) async {
    emit(AttributeFormLoading());
    try {
      final attr = await _get.execute(event.id);
      emit(AttributeFormLoaded(attr));
    } catch (e) {
      emit(AttributeFormError('Error al cargar atributo: $e'));
    }
  }

  Future<void> _onSubmit(
    SubmitAttributeFormEvent event,
    Emitter<AttributeFormState> emit,
  ) async {
    emit(AttributeFormSubmitting());
    try {
      final isNew = event.attribute.id.isEmpty;
      final result = isNew
          ? await _create.execute(event.attribute)
          : await _update.execute(event.attribute);
      emit(AttributeFormSuccess(result));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(AttributeFormError('Ya existe un atributo con ese slug'));
      } else {
        emit(AttributeFormError('Error al guardar atributo: $e'));
      }
    } catch (e) {
      emit(AttributeFormError('Error al guardar atributo: $e'));
    }
  }

  void _onReset(
    ResetAttributeFormEvent event,
    Emitter<AttributeFormState> emit,
  ) {
    emit(AttributeFormInitial());
  }
}
