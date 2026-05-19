import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';

/// Estados del quickstart.
sealed class QuickstartState {
  const QuickstartState();
}

class QuickstartInitial extends QuickstartState {
  const QuickstartInitial();
}

class QuickstartLoading extends QuickstartState {
  const QuickstartLoading();
}

/// Necesita completar quickstart (no hay productos).
class QuickstartNeeded extends QuickstartState {
  const QuickstartNeeded();
}

/// Ya está completo (tiene productos o fue descartado).
class QuickstartComplete extends QuickstartState {
  const QuickstartComplete();
}

class QuickstartError extends QuickstartState {
  final String message;
  const QuickstartError(this.message);
}

/// Cubit que valida si el tenant necesita quickstart.
class QuickstartCubit extends Cubit<QuickstartState> {
  final CatalogPort _catalogPort;

  QuickstartCubit(this._catalogPort) : super(const QuickstartInitial());

  /// Chequear si hay productos. Si no, mostrar quickstart.
  Future<void> checkIfNeeded() async {
    emit(const QuickstartLoading());
    try {
      final response = await _catalogPort.listProducts(pageSize: 1);
      // Si hay al menos un producto, no necesita quickstart
      if (response.totalCount > 0) {
        emit(const QuickstartComplete());
        return;
      }
      // Sin productos → necesita quickstart
      emit(const QuickstartNeeded());
    } catch (e) {
      // Si no se pueden cargar productos (error de red, tenant sin PIM configurado),
      // mostrar el quickstart para que el usuario configure su catálogo.
      emit(const QuickstartNeeded());
    }
  }

  /// Marcar quickstart como completo (usuario descartó o terminó).
  void complete() {
    emit(const QuickstartComplete());
  }
}
