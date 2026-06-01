import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class TemplateFormEvent {}

class LoadTemplateEvent extends TemplateFormEvent {
  final String id;
  LoadTemplateEvent(this.id);
}

class SubmitTemplateFormEvent extends TemplateFormEvent {
  final BusinessTypeTemplate template;
  SubmitTemplateFormEvent(this.template);
}

class GenerateWithAIEvent extends TemplateFormEvent {
  final String description;
  final String businessTypeId;

  GenerateWithAIEvent({
    required this.description,
    required this.businessTypeId,
  });
}

class ResetTemplateFormEvent extends TemplateFormEvent {}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class TemplateFormState {}

class TemplateFormInitial extends TemplateFormState {}

class TemplateFormLoading extends TemplateFormState {}

class TemplateFormSuccess extends TemplateFormState {
  final BusinessTypeTemplate template;
  TemplateFormSuccess(this.template);
}

/// La IA está procesando la solicitud de generación.
class TemplateFormAIGenerating extends TemplateFormState {}

/// La IA devolvió una sugerencia lista para editar antes de guardar.
class TemplateFormAISuccess extends TemplateFormState {
  final BusinessTypeTemplate template;
  TemplateFormAISuccess(this.template);
}

class TemplateFormError extends TemplateFormState {
  final String message;
  TemplateFormError(this.message);
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class TemplateFormBloc extends Bloc<TemplateFormEvent, TemplateFormState> {
  final GetTemplateUseCase _get;
  final CreateTemplateUseCase _create;
  final UpdateTemplateUseCase _update;
  final GenerateTemplateWithAIUseCase _generateAI;

  TemplateFormBloc({
    required GetTemplateUseCase get,
    required CreateTemplateUseCase create,
    required UpdateTemplateUseCase update,
    required GenerateTemplateWithAIUseCase generateAI,
  })  : _get = get,
        _create = create,
        _update = update,
        _generateAI = generateAI,
        super(TemplateFormInitial()) {
    on<LoadTemplateEvent>(_onLoad);
    on<SubmitTemplateFormEvent>(_onSubmit);
    on<GenerateWithAIEvent>(_onGenerateWithAI);
    on<ResetTemplateFormEvent>(_onReset);
  }

  Future<void> _onLoad(
    LoadTemplateEvent event,
    Emitter<TemplateFormState> emit,
  ) async {
    emit(TemplateFormLoading());
    try {
      final template = await _get.execute(event.id);
      emit(TemplateFormSuccess(template));
    } catch (e) {
      emit(TemplateFormError('Error al cargar template: $e'));
    }
  }

  Future<void> _onSubmit(
    SubmitTemplateFormEvent event,
    Emitter<TemplateFormState> emit,
  ) async {
    emit(TemplateFormLoading());
    try {
      final isNew = event.template.id.isEmpty;
      final result = isNew
          ? await _create.execute(event.template)
          : await _update.execute(event.template);
      emit(TemplateFormSuccess(result));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(TemplateFormError('Ya existe un template con ese nombre'));
      } else {
        emit(TemplateFormError('Error al guardar template: ${e.message}'));
      }
    } catch (e) {
      emit(TemplateFormError('Error al guardar template: $e'));
    }
  }

  Future<void> _onGenerateWithAI(
    GenerateWithAIEvent event,
    Emitter<TemplateFormState> emit,
  ) async {
    emit(TemplateFormAIGenerating());
    try {
      final template = await _generateAI.execute(
        event.description,
        event.businessTypeId,
      );
      emit(TemplateFormAISuccess(template));
    } on AIGenerationTimeoutException {
      emit(TemplateFormError(
        'La generación con IA superó el tiempo de espera. Intentá de nuevo.',
      ));
    } catch (e) {
      emit(TemplateFormError('Error al generar template con IA: $e'));
    }
  }

  void _onReset(
    ResetTemplateFormEvent event,
    Emitter<TemplateFormState> emit,
  ) {
    emit(TemplateFormInitial());
  }
}
