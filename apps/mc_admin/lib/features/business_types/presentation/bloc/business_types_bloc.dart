import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/business_types_repository.dart';
import '../../domain/models/business_type_model.dart';

// --- Events ---

abstract class BusinessTypesEvent {}

class LoadBusinessTypesEvent extends BusinessTypesEvent {}

// --- States ---

abstract class BusinessTypesState {}

class BusinessTypesInitial extends BusinessTypesState {}

class BusinessTypesLoading extends BusinessTypesState {}

class BusinessTypesLoaded extends BusinessTypesState {
  final List<BusinessType> businessTypes;
  BusinessTypesLoaded(this.businessTypes);
}

class BusinessTypesError extends BusinessTypesState {
  final String message;
  BusinessTypesError(this.message);
}

// --- Bloc ---

class BusinessTypesBloc extends Bloc<BusinessTypesEvent, BusinessTypesState> {
  final BusinessTypesRepository _repository;

  BusinessTypesBloc({required BusinessTypesRepository repository})
      : _repository = repository,
        super(BusinessTypesInitial()) {
    on<LoadBusinessTypesEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadBusinessTypesEvent event,
    Emitter<BusinessTypesState> emit,
  ) async {
    emit(BusinessTypesLoading());
    try {
      final types = await _repository.getAll();
      emit(BusinessTypesLoaded(types));
    } catch (e) {
      emit(BusinessTypesError('Error al cargar tipos de comercio: $e'));
    }
  }
}
