import 'package:flutter/material.dart';

/// Convierte un string hexadecimal en un [Color].
///
/// Acepta los formatos `#RGB`, `#RRGGBB` y `#AARRGGBB`, con o sin `#`
/// inicial y con espacios alrededor. Si no se especifica alpha, se asume
/// opaco (`FF`). Devuelve `null` si el valor es nulo, vacío o inválido.
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  var value = hex.trim().replaceFirst('#', '');
  if (value.isEmpty) return null;
  // #RGB -> #RRGGBB
  if (value.length == 3) {
    value = value.split('').map((c) => '$c$c').join();
  }
  // #RRGGBB -> #FFRRGGBB (opaco)
  if (value.length == 6) {
    value = 'FF$value';
  }
  if (value.length != 8) return null;
  final intColor = int.tryParse(value, radix: 16);
  return intColor == null ? null : Color(intColor);
}
