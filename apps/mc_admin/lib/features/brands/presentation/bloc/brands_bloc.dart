import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/brands_repository.dart';
import '../../domain/models/brand_model.dart';

// --- Events ---

abstract class BrandsEvent {}

class LoadBrandsEvent extends BrandsEvent {
  final String? search;
  final bool? verified;
  final bool? active;

  LoadBrandsEvent({this.search, this.verified, this.active});
}

class CreateBrandEvent extends BrandsEvent {
  final Brand brand;
  CreateBrandEvent(this.brand);
}

class UpdateBrandEvent extends BrandsEvent {
  final String id;
  final Brand brand;
  UpdateBrandEvent({required this.id, required this.brand});
}

class DeleteBrandEvent extends BrandsEvent {
  final String id;
  DeleteBrandEvent(this.id);
}

class VerifyBrandEvent extends BrandsEvent {
  final String id;
  VerifyBrandEvent(this.id);
}

// --- States ---

abstract class BrandsState {}

class BrandsInitial extends BrandsState {}

class BrandsLoading extends BrandsState {}

class BrandsLoaded extends BrandsState {
  final List<Brand> brands;
  BrandsLoaded(this.brands);
}

class BrandsError extends BrandsState {
  final String message;
  BrandsError(this.message);
}

// --- Bloc ---

class BrandsBloc extends Bloc<BrandsEvent, BrandsState> {
  final BrandsRepository _repository;

  BrandsBloc({required BrandsRepository repository})
      : _repository = repository,
        super(BrandsInitial()) {
    on<LoadBrandsEvent>(_onLoad);
    on<CreateBrandEvent>(_onCreate);
    on<UpdateBrandEvent>(_onUpdate);
    on<DeleteBrandEvent>(_onDelete);
    on<VerifyBrandEvent>(_onVerify);
  }

  Future<void> _onLoad(LoadBrandsEvent event, Emitter<BrandsState> emit) async {
    emit(BrandsLoading());
    try {
      final brands = await _repository.getAll(
        search: event.search,
        verified: event.verified,
        active: event.active,
      );
      emit(BrandsLoaded(brands));
    } catch (e) {
      emit(BrandsError('Error al cargar marcas: $e'));
    }
  }

  Future<void> _onCreate(
    CreateBrandEvent event,
    Emitter<BrandsState> emit,
  ) async {
    emit(BrandsLoading());
    try {
      await _repository.create(event.brand);
      final brands = await _repository.getAll();
      emit(BrandsLoaded(brands));
    } catch (e) {
      emit(BrandsError('Error al crear marca: $e'));
    }
  }

  Future<void> _onUpdate(
    UpdateBrandEvent event,
    Emitter<BrandsState> emit,
  ) async {
    emit(BrandsLoading());
    try {
      await _repository.update(event.id, event.brand);
      final brands = await _repository.getAll();
      emit(BrandsLoaded(brands));
    } catch (e) {
      emit(BrandsError('Error al actualizar marca: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteBrandEvent event,
    Emitter<BrandsState> emit,
  ) async {
    emit(BrandsLoading());
    try {
      await _repository.delete(event.id);
      final brands = await _repository.getAll();
      emit(BrandsLoaded(brands));
    } catch (e) {
      emit(BrandsError('Error al eliminar marca: $e'));
    }
  }

  Future<void> _onVerify(
    VerifyBrandEvent event,
    Emitter<BrandsState> emit,
  ) async {
    emit(BrandsLoading());
    try {
      await _repository.verify(event.id);
      final brands = await _repository.getAll();
      emit(BrandsLoaded(brands));
    } catch (e) {
      emit(BrandsError('Error al verificar marca: $e'));
    }
  }
}
