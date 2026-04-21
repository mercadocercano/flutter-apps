import 'package:equatable/equatable.dart';

/// Value object para tenant ID. Valida formato UUID.
class TenantId extends Equatable {
  final String value;

  TenantId(this.value) {
    if (value.isEmpty) {
      throw ArgumentError('TenantId no puede estar vacío');
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
