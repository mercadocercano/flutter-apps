import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class TemplatesEvent {}

class LoadTemplatesEvent extends TemplatesEvent {
  final String businessTypeId;
  LoadTemplatesEvent(this.businessTypeId);
}

class RefreshTemplatesEvent extends TemplatesEvent {}

class DeleteTemplateEvent extends TemplatesEvent {
  final String id;
  DeleteTemplateEvent(this.id);
}

class DuplicateTemplateEvent extends TemplatesEvent {
  final String id;
  DuplicateTemplateEvent(this.id);
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class TemplatesState {}

class TemplatesInitial extends TemplatesState {}

class TemplatesLoading extends TemplatesState {}

class TemplatesLoaded extends TemplatesState {
  final List<BusinessTypeTemplate> templates;
  final String businessTypeId;

  TemplatesLoaded({
    required this.templates,
    required this.businessTypeId,
  });
}

class TemplatesError extends TemplatesState {
  final String message;
  TemplatesError(this.message);
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class TemplatesBloc extends Bloc<TemplatesEvent, TemplatesState> {
  final ListTemplatesUseCase _list;
  final DeleteTemplateUseCase _delete;
  final DuplicateTemplateUseCase _duplicate;

  String? _currentBusinessTypeId;

  TemplatesBloc({
    required ListTemplatesUseCase list,
    required DeleteTemplateUseCase delete,
    required DuplicateTemplateUseCase duplicate,
  })  : _list = list,
        _delete = delete,
        _duplicate = duplicate,
        super(TemplatesInitial()) {
    on<LoadTemplatesEvent>(_onLoad);
    on<RefreshTemplatesEvent>(_onRefresh);
    on<DeleteTemplateEvent>(_onDelete);
    on<DuplicateTemplateEvent>(_onDuplicate);
  }

  Future<void> _onLoad(
    LoadTemplatesEvent event,
    Emitter<TemplatesState> emit,
  ) async {
    emit(TemplatesLoading());
    _currentBusinessTypeId = event.businessTypeId;

    try {
      final templates = await _list.execute(event.businessTypeId);
      emit(TemplatesLoaded(
        templates: templates,
        businessTypeId: event.businessTypeId,
      ));
    } catch (e) {
      emit(TemplatesError('Error al cargar templates: $e'));
    }
  }

  Future<void> _onRefresh(
    RefreshTemplatesEvent event,
    Emitter<TemplatesState> emit,
  ) async {
    if (_currentBusinessTypeId == null) return;
    add(LoadTemplatesEvent(_currentBusinessTypeId!));
  }

  Future<void> _onDelete(
    DeleteTemplateEvent event,
    Emitter<TemplatesState> emit,
  ) async {
    try {
      await _delete.execute(event.id);
      add(RefreshTemplatesEvent());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(TemplatesError('Template en uso, no se puede eliminar'));
      } else {
        emit(TemplatesError('Error al eliminar template: ${e.message}'));
      }
    } catch (e) {
      emit(TemplatesError('Error al eliminar template: $e'));
    }
  }

  Future<void> _onDuplicate(
    DuplicateTemplateEvent event,
    Emitter<TemplatesState> emit,
  ) async {
    try {
      await _duplicate.execute(event.id);
      add(RefreshTemplatesEvent());
    } catch (e) {
      emit(TemplatesError('Error al duplicar template: $e'));
    }
  }
}
