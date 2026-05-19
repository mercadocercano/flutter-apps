import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/categories_repository.dart';
import '../../domain/models/category_model.dart';

// --- Events ---

abstract class CategoriesEvent {}

class LoadCategoriesEvent extends CategoriesEvent {}

class CreateCategoryEvent extends CategoriesEvent {
  final Category category;
  CreateCategoryEvent(this.category);
}

class UpdateCategoryEvent extends CategoriesEvent {
  final String id;
  final Category category;
  UpdateCategoryEvent({required this.id, required this.category});
}

class DeleteCategoryEvent extends CategoriesEvent {
  final String id;
  DeleteCategoryEvent(this.id);
}

// --- States ---

abstract class CategoriesState {}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<Category> categories;
  CategoriesLoaded(this.categories);
}

class CategoriesError extends CategoriesState {
  final String message;
  CategoriesError(this.message);
}

// --- Bloc ---

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesRepository _repository;

  CategoriesBloc({required CategoriesRepository repository})
      : _repository = repository,
        super(CategoriesInitial()) {
    on<LoadCategoriesEvent>(_onLoad);
    on<CreateCategoryEvent>(_onCreate);
    on<UpdateCategoryEvent>(_onUpdate);
    on<DeleteCategoryEvent>(_onDelete);
  }

  Future<void> _onLoad(
    LoadCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      final categories = await _repository.getTree();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(CategoriesError('Error al cargar categorias: $e'));
    }
  }

  Future<void> _onCreate(
    CreateCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      await _repository.create(event.category);
      final categories = await _repository.getTree();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(CategoriesError('Error al crear categoria: $e'));
    }
  }

  Future<void> _onUpdate(
    UpdateCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      await _repository.update(event.id, event.category);
      final categories = await _repository.getTree();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(CategoriesError('Error al actualizar categoria: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      await _repository.delete(event.id);
      final categories = await _repository.getTree();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(CategoriesError('Error al eliminar categoria: $e'));
    }
  }
}
