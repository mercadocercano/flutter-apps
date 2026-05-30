import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/dev_metrics_repository.dart';
import '../../domain/models/dev_metrics_model.dart';

// --- Events ---

abstract class DevMetricsEvent {}

class LoadDevMetricsEvent extends DevMetricsEvent {
  final int days;

  LoadDevMetricsEvent({this.days = 30});
}

// --- States ---

abstract class DevMetricsState {}

class DevMetricsInitial extends DevMetricsState {}

class DevMetricsLoading extends DevMetricsState {}

class DevMetricsLoaded extends DevMetricsState {
  final DevMetrics metrics;
  final int days;

  DevMetricsLoaded(this.metrics, {required this.days});
}

class DevMetricsError extends DevMetricsState {
  final String message;

  DevMetricsError(this.message);
}

// --- Bloc ---

class DevMetricsBloc extends Bloc<DevMetricsEvent, DevMetricsState> {
  final DevMetricsRepository _repository;

  DevMetricsBloc({required DevMetricsRepository repository})
      : _repository = repository,
        super(DevMetricsInitial()) {
    on<LoadDevMetricsEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadDevMetricsEvent event,
    Emitter<DevMetricsState> emit,
  ) async {
    emit(DevMetricsLoading());
    try {
      final metrics = await _repository.fetchMetrics(days: event.days);
      emit(DevMetricsLoaded(metrics, days: event.days));
    } catch (e) {
      emit(DevMetricsError('Error al cargar métricas: $e'));
    }
  }
}
