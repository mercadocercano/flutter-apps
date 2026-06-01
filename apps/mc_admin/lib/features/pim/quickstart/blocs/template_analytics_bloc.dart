import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class TemplateAnalyticsEvent {}

class LoadTemplateAnalyticsEvent extends TemplateAnalyticsEvent {
  final String templateId;
  LoadTemplateAnalyticsEvent(this.templateId);
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class TemplateAnalyticsState {}

class TemplateAnalyticsInitial extends TemplateAnalyticsState {}

class TemplateAnalyticsLoading extends TemplateAnalyticsState {}

class TemplateAnalyticsLoaded extends TemplateAnalyticsState {
  final TemplateAnalytics analytics;
  TemplateAnalyticsLoaded(this.analytics);
}

class TemplateAnalyticsError extends TemplateAnalyticsState {
  final String message;
  TemplateAnalyticsError(this.message);
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class TemplateAnalyticsBloc
    extends Bloc<TemplateAnalyticsEvent, TemplateAnalyticsState> {
  final GetTemplateAnalyticsUseCase _getAnalytics;

  TemplateAnalyticsBloc({
    required GetTemplateAnalyticsUseCase getAnalytics,
  })  : _getAnalytics = getAnalytics,
        super(TemplateAnalyticsInitial()) {
    on<LoadTemplateAnalyticsEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadTemplateAnalyticsEvent event,
    Emitter<TemplateAnalyticsState> emit,
  ) async {
    emit(TemplateAnalyticsLoading());
    try {
      final analytics = await _getAnalytics.execute(event.templateId);
      emit(TemplateAnalyticsLoaded(analytics));
    } catch (e) {
      emit(TemplateAnalyticsError('Error al cargar analytics: $e'));
    }
  }
}
