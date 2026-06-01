import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class ProductFormEvent {}

class LoadProductEvent extends ProductFormEvent {
  final String id;
  LoadProductEvent(this.id);
}

class SubmitCreateProductEvent extends ProductFormEvent {
  final GlobalProduct product;
  SubmitCreateProductEvent(this.product);
}

class SubmitUpdateProductEvent extends ProductFormEvent {
  final GlobalProduct product;
  SubmitUpdateProductEvent(this.product);
}

class DeleteProductEvent extends ProductFormEvent {
  final String id;
  DeleteProductEvent(this.id);
}

class VerifyProductEvent extends ProductFormEvent {
  final String id;
  VerifyProductEvent(this.id);
}

class UnverifyProductEvent extends ProductFormEvent {
  final String id;
  UnverifyProductEvent(this.id);
}

class ResetProductFormEvent extends ProductFormEvent {}

// --- States ---

abstract class ProductFormState {}

class ProductFormInitial extends ProductFormState {}

class ProductFormLoading extends ProductFormState {}

class ProductFormLoaded extends ProductFormState {
  final GlobalProduct product;
  ProductFormLoaded(this.product);
}

class ProductFormSubmitting extends ProductFormState {}

class ProductFormSuccess extends ProductFormState {
  final GlobalProduct? product;
  ProductFormSuccess({this.product});
}

class ProductFormDeleted extends ProductFormState {}

class ProductFormError extends ProductFormState {
  final String message;
  ProductFormError(this.message);
}

// --- Bloc ---

class ProductFormBloc extends Bloc<ProductFormEvent, ProductFormState> {
  final GetGlobalProductUseCase _get;
  final CreateGlobalProductUseCase _create;
  final UpdateGlobalProductUseCase _update;
  final DeleteGlobalProductUseCase _delete;
  final VerifyGlobalProductUseCase _verify;
  final UnverifyGlobalProductUseCase _unverify;

  ProductFormBloc({
    required GetGlobalProductUseCase get,
    required CreateGlobalProductUseCase create,
    required UpdateGlobalProductUseCase update,
    required DeleteGlobalProductUseCase delete,
    required VerifyGlobalProductUseCase verify,
    required UnverifyGlobalProductUseCase unverify,
  })  : _get = get,
        _create = create,
        _update = update,
        _delete = delete,
        _verify = verify,
        _unverify = unverify,
        super(ProductFormInitial()) {
    on<LoadProductEvent>(_onLoad);
    on<SubmitCreateProductEvent>(_onCreate);
    on<SubmitUpdateProductEvent>(_onUpdate);
    on<DeleteProductEvent>(_onDelete);
    on<VerifyProductEvent>(_onVerify);
    on<UnverifyProductEvent>(_onUnverify);
    on<ResetProductFormEvent>(_onReset);
  }

  Future<void> _onLoad(
    LoadProductEvent event,
    Emitter<ProductFormState> emit,
  ) async {
    emit(ProductFormLoading());
    try {
      final product = await _get.execute(event.id);
      emit(ProductFormLoaded(product));
    } catch (e) {
      emit(ProductFormError('Error al cargar producto: $e'));
    }
  }

  Future<void> _onCreate(
    SubmitCreateProductEvent event,
    Emitter<ProductFormState> emit,
  ) async {
    emit(ProductFormSubmitting());
    try {
      final product = await _create.execute(event.product);
      emit(ProductFormSuccess(product: product));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(ProductFormError('Ya existe un producto con ese SKU'));
      } else {
        emit(ProductFormError('Error al crear producto: $e'));
      }
    } catch (e) {
      emit(ProductFormError('Error al crear producto: $e'));
    }
  }

  Future<void> _onUpdate(
    SubmitUpdateProductEvent event,
    Emitter<ProductFormState> emit,
  ) async {
    emit(ProductFormSubmitting());
    try {
      final product = await _update.execute(event.product);
      emit(ProductFormSuccess(product: product));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(ProductFormError('Ya existe un producto con ese SKU'));
      } else {
        emit(ProductFormError('Error al actualizar producto: $e'));
      }
    } catch (e) {
      emit(ProductFormError('Error al actualizar producto: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteProductEvent event,
    Emitter<ProductFormState> emit,
  ) async {
    emit(ProductFormSubmitting());
    try {
      await _delete.execute(event.id);
      emit(ProductFormDeleted());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(ProductFormError(
            'Producto en uso por comercios, no se puede eliminar'));
      } else {
        emit(ProductFormError('Error al eliminar producto: $e'));
      }
    } catch (e) {
      emit(ProductFormError('Error al eliminar producto: $e'));
    }
  }

  Future<void> _onVerify(
    VerifyProductEvent event,
    Emitter<ProductFormState> emit,
  ) async {
    emit(ProductFormSubmitting());
    try {
      final product = await _verify.execute(event.id);
      emit(ProductFormSuccess(product: product));
    } catch (e) {
      emit(ProductFormError('Error al verificar producto: $e'));
    }
  }

  Future<void> _onUnverify(
    UnverifyProductEvent event,
    Emitter<ProductFormState> emit,
  ) async {
    emit(ProductFormSubmitting());
    try {
      final product = await _unverify.execute(event.id);
      emit(ProductFormSuccess(product: product));
    } catch (e) {
      emit(ProductFormError('Error al desverificar producto: $e'));
    }
  }

  void _onReset(
    ResetProductFormEvent event,
    Emitter<ProductFormState> emit,
  ) {
    emit(ProductFormInitial());
  }
}
