import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class SourcesEvent {}

class LoadSourcesEvent extends SourcesEvent {
  final String? status;
  LoadSourcesEvent({this.status});
}

class RefreshSourcesEvent extends SourcesEvent {}

class TriggerSourceEvent extends SourcesEvent {
  final String id;
  TriggerSourceEvent(this.id);
}

class DeleteSourceEvent extends SourcesEvent {
  final String id;
  DeleteSourceEvent(this.id);
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class SourcesState {}

class SourcesInitial extends SourcesState {}

class SourcesLoading extends SourcesState {}

class SourcesLoaded extends SourcesState {
  final List<WebSource> sources;
  final String? statusFilter;

  SourcesLoaded({
    required this.sources,
    this.statusFilter,
  });
}

class SourcesError extends SourcesState {
  final String message;
  SourcesError(this.message);
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class SourcesBloc extends Bloc<SourcesEvent, SourcesState> {
  final ListSourcesUseCase _list;
  final TriggerSourceUseCase _trigger;
  final DeleteSourceUseCase _delete;

  String? _currentStatus;

  SourcesBloc({
    required ListSourcesUseCase list,
    required TriggerSourceUseCase trigger,
    required DeleteSourceUseCase delete,
  })  : _list = list,
        _trigger = trigger,
        _delete = delete,
        super(SourcesInitial()) {
    on<LoadSourcesEvent>(_onLoad);
    on<RefreshSourcesEvent>(_onRefresh);
    on<TriggerSourceEvent>(_onTrigger);
    on<DeleteSourceEvent>(_onDelete);
  }

  Future<void> _onLoad(
    LoadSourcesEvent event,
    Emitter<SourcesState> emit,
  ) async {
    emit(SourcesLoading());
    _currentStatus = event.status;

    try {
      final page = await _list.execute(status: event.status);
      emit(SourcesLoaded(
        sources: page.items,
        statusFilter: event.status,
      ));
    } catch (e) {
      emit(SourcesError('Error al cargar fuentes: $e'));
    }
  }

  Future<void> _onRefresh(
    RefreshSourcesEvent event,
    Emitter<SourcesState> emit,
  ) async {
    add(LoadSourcesEvent(status: _currentStatus));
  }

  Future<void> _onTrigger(
    TriggerSourceEvent event,
    Emitter<SourcesState> emit,
  ) async {
    try {
      await _trigger.execute(event.id);
      add(RefreshSourcesEvent());
    } catch (e) {
      emit(SourcesError('Error al ejecutar fuente: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteSourceEvent event,
    Emitter<SourcesState> emit,
  ) async {
    try {
      await _delete.execute(event.id);
      add(RefreshSourcesEvent());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(SourcesError('La fuente tiene jobs en ejecución, no se puede eliminar'));
      } else {
        emit(SourcesError('Error al eliminar fuente: ${e.message}'));
      }
    } catch (e) {
      emit(SourcesError('Error al eliminar fuente: $e'));
    }
  }
}
