import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// ---------------------------------------------------------------------------
// Timer factory type — injectable para tests con fake timer.
// Firma idéntica a Timer.periodic.
// ---------------------------------------------------------------------------

typedef TimerFactory = Timer Function(Duration, void Function(Timer));

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class JobsEvent {}

class LoadJobsEvent extends JobsEvent {
  final String? status;
  final String? sourceId;

  LoadJobsEvent({this.status, this.sourceId});
}

class RefreshJobsEvent extends JobsEvent {}

class CancelJobEvent extends JobsEvent {
  final String id;
  CancelJobEvent(this.id);
}

class RetryJobEvent extends JobsEvent {
  final String id;
  RetryJobEvent(this.id);
}

class StopPollingEvent extends JobsEvent {}

/// Evento interno disparado por Timer.periodic.
class _PollTickEvent extends JobsEvent {}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class JobsState {}

class JobsInitial extends JobsState {}

class JobsLoading extends JobsState {}

class JobsLoaded extends JobsState {
  final List<WebJob> jobs;
  final bool hasRunningJobs;
  final String? statusFilter;
  final String? sourceIdFilter;

  JobsLoaded({
    required this.jobs,
    required this.hasRunningJobs,
    this.statusFilter,
    this.sourceIdFilter,
  });
}

class JobsError extends JobsState {
  final String message;
  JobsError(this.message);
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class JobsBloc extends Bloc<JobsEvent, JobsState> {
  static const _pollInterval = Duration(seconds: 5);

  final ListJobsUseCase _list;
  final CancelJobUseCase _cancel;
  final RetryJobUseCase _retry;
  final TimerFactory _timerFactory;

  Timer? _pollTimer;
  String? _currentStatus;
  String? _currentSourceId;

  JobsBloc({
    required ListJobsUseCase list,
    required CancelJobUseCase cancel,
    required RetryJobUseCase retry,
    TimerFactory timerFactory = Timer.periodic,
  })  : _list = list,
        _cancel = cancel,
        _retry = retry,
        _timerFactory = timerFactory,
        super(JobsInitial()) {
    on<LoadJobsEvent>(_onLoad);
    on<RefreshJobsEvent>(_onRefresh);
    on<CancelJobEvent>(_onCancel);
    on<RetryJobEvent>(_onRetry);
    on<StopPollingEvent>(_onStopPolling);
    on<_PollTickEvent>(_onPollTick);
  }

  Future<void> _onLoad(
    LoadJobsEvent event,
    Emitter<JobsState> emit,
  ) async {
    emit(JobsLoading());
    _currentStatus = event.status;
    _currentSourceId = event.sourceId;

    try {
      final page = await _list.execute(
        status: event.status,
        sourceId: event.sourceId,
      );
      final hasRunning = page.items.any((j) => j.isActive);

      emit(JobsLoaded(
        jobs: page.items,
        hasRunningJobs: hasRunning,
        statusFilter: event.status,
        sourceIdFilter: event.sourceId,
      ));

      _updatePolling(hasRunning);
    } catch (e) {
      emit(JobsError('Error al cargar jobs: $e'));
    }
  }

  Future<void> _onRefresh(
    RefreshJobsEvent event,
    Emitter<JobsState> emit,
  ) async {
    add(LoadJobsEvent(status: _currentStatus, sourceId: _currentSourceId));
  }

  Future<void> _onCancel(
    CancelJobEvent event,
    Emitter<JobsState> emit,
  ) async {
    try {
      await _cancel.execute(event.id);
      add(RefreshJobsEvent());
    } catch (e) {
      emit(JobsError('Error al cancelar job: $e'));
    }
  }

  Future<void> _onRetry(
    RetryJobEvent event,
    Emitter<JobsState> emit,
  ) async {
    try {
      await _retry.execute(event.id);
      add(RefreshJobsEvent());
    } catch (e) {
      emit(JobsError('Error al reintentar job: $e'));
    }
  }

  void _onStopPolling(
    StopPollingEvent event,
    Emitter<JobsState> emit,
  ) {
    _cancelTimer();
  }

  Future<void> _onPollTick(
    _PollTickEvent event,
    Emitter<JobsState> emit,
  ) async {
    // Recarga silenciosa — sin emitir Loading para no interrumpir la UI
    try {
      final page = await _list.execute(
        status: _currentStatus,
        sourceId: _currentSourceId,
      );
      final hasRunning = page.items.any((j) => j.isActive);

      emit(JobsLoaded(
        jobs: page.items,
        hasRunningJobs: hasRunning,
        statusFilter: _currentStatus,
        sourceIdFilter: _currentSourceId,
      ));

      // Detiene el polling si ya no hay jobs running
      if (!hasRunning) _cancelTimer();
    } catch (_) {
      // Ignoramos errores de poll silencioso para no interrumpir la UI
    }
  }

  // -------------------------------------------------------------------------
  // Helpers de polling
  // -------------------------------------------------------------------------

  void _updatePolling(bool hasRunning) {
    if (hasRunning && _pollTimer == null) {
      _startPolling();
    } else if (!hasRunning) {
      _cancelTimer();
    }
  }

  void _startPolling() {
    _pollTimer = _timerFactory(_pollInterval, (_) => add(_PollTickEvent()));
  }

  void _cancelTimer() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
