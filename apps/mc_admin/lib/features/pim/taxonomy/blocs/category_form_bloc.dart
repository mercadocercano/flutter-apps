import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class CategoryFormEvent {}

class SubmitCreateCategoryEvent extends CategoryFormEvent {
  final CreateCategoryParams params;
  SubmitCreateCategoryEvent(this.params);
}

class SubmitUpdateCategoryEvent extends CategoryFormEvent {
  final String id;
  final UpdateCategoryParams params;
  SubmitUpdateCategoryEvent({required this.id, required this.params});
}

class DeleteCategoryEvent extends CategoryFormEvent {
  final String id;
  DeleteCategoryEvent(this.id);
}

// --- States ---

abstract class CategoryFormState {}

class CategoryFormInitial extends CategoryFormState {}

class CategoryFormSubmitting extends CategoryFormState {}

class CategoryFormSuccess extends CategoryFormState {
  final MarketplaceCategory? entity;
  CategoryFormSuccess({this.entity});
}

class CategoryFormDeleted extends CategoryFormState {}

class CategoryFormError extends CategoryFormState {
  final String message;
  CategoryFormError(this.message);
}

// --- Bloc ---

class CategoryFormBloc extends Bloc<CategoryFormEvent, CategoryFormState> {
  final CreateCategoryUseCase _create;
  final UpdateCategoryUseCase _update;
  final DeleteCategoryUseCase _delete;

  CategoryFormBloc({
    required CreateCategoryUseCase create,
    required UpdateCategoryUseCase update,
    required DeleteCategoryUseCase delete,
  })  : _create = create,
        _update = update,
        _delete = delete,
        super(CategoryFormInitial()) {
    on<SubmitCreateCategoryEvent>(_onCreate);
    on<SubmitUpdateCategoryEvent>(_onUpdate);
    on<DeleteCategoryEvent>(_onDelete);
  }

  Future<void> _onCreate(
    SubmitCreateCategoryEvent event,
    Emitter<CategoryFormState> emit,
  ) async {
    emit(CategoryFormSubmitting());
    try {
      final entity = await _create.execute(event.params);
      emit(CategoryFormSuccess(entity: entity));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(CategoryFormError('Ya existe una categoría con ese slug'));
      } else {
        emit(CategoryFormError('Error al crear categoría: $e'));
      }
    } catch (e) {
      emit(CategoryFormError('Error al crear categoría: $e'));
    }
  }

  Future<void> _onUpdate(
    SubmitUpdateCategoryEvent event,
    Emitter<CategoryFormState> emit,
  ) async {
    emit(CategoryFormSubmitting());
    try {
      final entity = await _update.execute(event.id, event.params);
      emit(CategoryFormSuccess(entity: entity));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(CategoryFormError('Ya existe una categoría con ese slug'));
      } else {
        emit(CategoryFormError('Error al actualizar categoría: $e'));
      }
    } catch (e) {
      emit(CategoryFormError('Error al actualizar categoría: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteCategoryEvent event,
    Emitter<CategoryFormState> emit,
  ) async {
    emit(CategoryFormSubmitting());
    try {
      await _delete.execute(event.id);
      emit(CategoryFormDeleted());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(CategoryFormError(
            'No se puede eliminar: la categoría tiene subcategorías'));
      } else {
        emit(CategoryFormError('Error al eliminar categoría: $e'));
      }
    } catch (e) {
      emit(CategoryFormError('Error al eliminar categoría: $e'));
    }
  }
}
