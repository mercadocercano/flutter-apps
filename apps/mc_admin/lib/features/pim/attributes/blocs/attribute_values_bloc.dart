import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class AttributeValuesEvent {}

class LoadAttributeValuesEvent extends AttributeValuesEvent {
  final String attributeId;
  LoadAttributeValuesEvent(this.attributeId);
}

class CreateAttributeValueEvent extends AttributeValuesEvent {
  final AttributeValue value;
  CreateAttributeValueEvent(this.value);
}

class UpdateAttributeValueEvent extends AttributeValuesEvent {
  final AttributeValue value;
  UpdateAttributeValueEvent(this.value);
}

class DeleteAttributeValueEvent extends AttributeValuesEvent {
  final String attributeId;
  final String valueId;
  DeleteAttributeValueEvent({
    required this.attributeId,
    required this.valueId,
  });
}

// --- States ---

abstract class AttributeValuesState {}

class AttributeValuesInitial extends AttributeValuesState {}

class AttributeValuesLoading extends AttributeValuesState {}

class AttributeValuesLoaded extends AttributeValuesState {
  final List<AttributeValue> values;
  AttributeValuesLoaded(this.values);
}

class AttributeValuesError extends AttributeValuesState {
  final String message;
  AttributeValuesError(this.message);
}

// --- Bloc ---

class AttributeValuesBloc
    extends Bloc<AttributeValuesEvent, AttributeValuesState> {
  final ListAttributeValuesUseCase _list;
  final CreateAttributeValueUseCase _create;
  final UpdateAttributeValueUseCase _update;
  final DeleteAttributeValueUseCase _delete;

  String? _currentAttributeId;

  AttributeValuesBloc({
    required ListAttributeValuesUseCase list,
    required CreateAttributeValueUseCase create,
    required UpdateAttributeValueUseCase update,
    required DeleteAttributeValueUseCase delete,
  })  : _list = list,
        _create = create,
        _update = update,
        _delete = delete,
        super(AttributeValuesInitial()) {
    on<LoadAttributeValuesEvent>(_onLoad);
    on<CreateAttributeValueEvent>(_onCreate);
    on<UpdateAttributeValueEvent>(_onUpdate);
    on<DeleteAttributeValueEvent>(_onDelete);
  }

  Future<void> _onLoad(
    LoadAttributeValuesEvent event,
    Emitter<AttributeValuesState> emit,
  ) async {
    emit(AttributeValuesLoading());
    _currentAttributeId = event.attributeId;
    try {
      final values = await _list.execute(event.attributeId);
      emit(AttributeValuesLoaded(values));
    } catch (e) {
      emit(AttributeValuesError('Error al cargar valores: $e'));
    }
  }

  Future<void> _onCreate(
    CreateAttributeValueEvent event,
    Emitter<AttributeValuesState> emit,
  ) async {
    try {
      await _create.execute(event.value);
      if (_currentAttributeId != null) {
        add(LoadAttributeValuesEvent(_currentAttributeId!));
      }
    } on DioException catch (e) {
      emit(AttributeValuesError('Error al crear valor: $e'));
    } catch (e) {
      emit(AttributeValuesError('Error al crear valor: $e'));
    }
  }

  Future<void> _onUpdate(
    UpdateAttributeValueEvent event,
    Emitter<AttributeValuesState> emit,
  ) async {
    try {
      await _update.execute(event.value);
      if (_currentAttributeId != null) {
        add(LoadAttributeValuesEvent(_currentAttributeId!));
      }
    } on DioException catch (e) {
      emit(AttributeValuesError('Error al actualizar valor: $e'));
    } catch (e) {
      emit(AttributeValuesError('Error al actualizar valor: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteAttributeValueEvent event,
    Emitter<AttributeValuesState> emit,
  ) async {
    try {
      await _delete.execute(event.attributeId, event.valueId);
      add(LoadAttributeValuesEvent(event.attributeId));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(AttributeValuesError('Valor en uso, no se puede eliminar'));
      } else {
        emit(AttributeValuesError('Error al eliminar valor: $e'));
      }
    } catch (e) {
      emit(AttributeValuesError('Error al eliminar valor: $e'));
    }
  }
}
