import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class SourceFormEvent {}

class LoadSourceEvent extends SourceFormEvent {
  final String id;
  LoadSourceEvent(this.id);
}

class SubmitSourceFormEvent extends SourceFormEvent {
  final WebSource source;
  SubmitSourceFormEvent(this.source);
}

class ResetSourceFormEvent extends SourceFormEvent {}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class SourceFormState {}

class SourceFormInitial extends SourceFormState {}

class SourceFormLoading extends SourceFormState {}

class SourceFormSuccess extends SourceFormState {
  final WebSource source;
  SourceFormSuccess(this.source);
}

class SourceFormError extends SourceFormState {
  final String message;
  SourceFormError(this.message);
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class SourceFormBloc extends Bloc<SourceFormEvent, SourceFormState> {
  final GetSourceUseCase _get;
  final CreateSourceUseCase _create;
  final UpdateSourceUseCase _update;

  SourceFormBloc({
    required GetSourceUseCase get,
    required CreateSourceUseCase create,
    required UpdateSourceUseCase update,
  })  : _get = get,
        _create = create,
        _update = update,
        super(SourceFormInitial()) {
    on<LoadSourceEvent>(_onLoad);
    on<SubmitSourceFormEvent>(_onSubmit);
    on<ResetSourceFormEvent>(_onReset);
  }

  Future<void> _onLoad(
    LoadSourceEvent event,
    Emitter<SourceFormState> emit,
  ) async {
    emit(SourceFormLoading());
    try {
      final source = await _get.execute(event.id);
      emit(SourceFormSuccess(source));
    } catch (e) {
      emit(SourceFormError('Error al cargar fuente: $e'));
    }
  }

  Future<void> _onSubmit(
    SubmitSourceFormEvent event,
    Emitter<SourceFormState> emit,
  ) async {
    emit(SourceFormLoading());
    try {
      final isNew = event.source.id.isEmpty;
      final result = isNew
          ? await _create.execute(event.source)
          : await _update.execute(event.source);
      emit(SourceFormSuccess(result));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(SourceFormError('Ya existe una fuente con esa URL'));
      } else {
        emit(SourceFormError('Error al guardar fuente: ${e.message}'));
      }
    } catch (e) {
      emit(SourceFormError('Error al guardar fuente: $e'));
    }
  }

  void _onReset(
    ResetSourceFormEvent event,
    Emitter<SourceFormState> emit,
  ) {
    emit(SourceFormInitial());
  }
}
