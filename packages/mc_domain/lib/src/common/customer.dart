import 'package:equatable/equatable.dart';

/// Cliente del comercio.
class Customer extends Equatable {
  final String id;
  final String tenantId;
  final String name;
  final String? email;
  final String? phone;
  final String? document;

  const Customer({
    required this.id,
    required this.tenantId,
    required this.name,
    this.email,
    this.phone,
    this.document,
  });

  /// "Consumidor Final" — cliente genérico por defecto.
  bool get isDefault => name == 'Consumidor Final';

  /// Texto de búsqueda visible: nombre + teléfono si tiene.
  String get displayName => phone != null ? '$name ($phone)' : name;

  @override
  List<Object?> get props => [id];
}
