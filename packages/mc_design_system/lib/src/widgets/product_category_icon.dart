import 'package:flutter/material.dart';

/// Resuelve el [IconData] de Material correspondiente a una categoría de producto
/// o tipo de negocio, con matching parcial e insensible a mayúsculas/tildes.
///
/// Uso:
/// ```dart
/// final icon = ProductCategoryIcon.iconFor(category: 'Lácteos');
/// ```
abstract final class ProductCategoryIcon {
  /// Retorna el [IconData] más apropiado para [category] o [businessType].
  ///
  /// Prioriza [category]. Si no hay match, intenta con [businessType].
  /// Fallback: [Icons.inventory_2_outlined].
  static IconData iconFor({String? category, String? businessType}) {
    final fromCategory = _resolve(category);
    if (fromCategory != null) return fromCategory;

    final fromBusiness = _resolve(businessType);
    if (fromBusiness != null) return fromBusiness;

    return Icons.inventory_2_outlined;
  }

  static IconData? _resolve(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final s = _normalize(input);

    if (_any(s, ['bebida', 'gaseosa', 'jugo', 'agua', 'refresco', 'soda', 'infusion', 'te', 'cafe'])) {
      return Icons.local_drink_outlined;
    }
    if (_any(s, ['cerveza'])) return Icons.sports_bar_outlined;
    if (_any(s, ['vino', 'licor', 'fernet', 'whisky', 'vodka', 'alcohol', 'bebida-alc'])) {
      return Icons.wine_bar_outlined;
    }
    if (_any(s, ['lacteo', 'leche', 'yogur', 'queso', 'manteca', 'crema', 'yoghurt'])) {
      return Icons.egg_alt_outlined;
    }
    if (_any(s, ['carne', 'pollo', 'pescado', 'mariscos', 'fiambre', 'embutido'])) {
      return Icons.set_meal_outlined;
    }
    if (_any(s, ['pan', 'panaderia', 'galletita', 'facturas', 'medialunas', 'trigo', 'harina'])) {
      return Icons.bakery_dining_outlined;
    }
    if (_any(s, ['fruta', 'verdura', 'vegetal', 'hortal', 'produce', 'greengrocer'])) {
      return Icons.eco_outlined;
    }
    if (_any(s, ['limpieza', 'detergente', 'lavandina', 'jabon', 'cleaning'])) {
      return Icons.cleaning_services_outlined;
    }
    if (_any(s, ['higiene', 'perfume', 'cosmetico', 'shampoo', 'desodorante', 'cosmetica', 'perfumeria', 'cosmetics'])) {
      return Icons.soap_outlined;
    }
    if (_any(s, ['golosina', 'chocolate', 'caramelo', 'alfajor', 'candy', 'dulce'])) {
      return Icons.cake_outlined;
    }
    if (_any(s, ['snack', 'chips', 'mani', 'pochoclo'])) {
      return Icons.fastfood_outlined;
    }
    if (_any(s, ['electronica', 'celular', 'tecnologia', 'electrodomestico', 'computadora'])) {
      return Icons.devices_outlined;
    }
    if (_any(s, ['ferreteria', 'herramienta', 'tornillo', 'pintura', 'hardware'])) {
      return Icons.hardware_outlined;
    }
    if (_any(s, ['papeleria', 'libreria', 'cuaderno', 'libreria'])) {
      return Icons.auto_stories_outlined;
    }
    if (_any(s, ['ropa', 'indumentaria', 'calzado', 'textil'])) {
      return Icons.checkroom_outlined;
    }
    if (_any(s, ['medicamento', 'farmacia', 'remedio', 'vitamina', 'pharmacy'])) {
      return Icons.medical_services_outlined;
    }
    if (_any(s, ['congelado', 'helado', 'frozen'])) {
      return Icons.ac_unit_outlined;
    }
    if (_any(s, ['aceite', 'condimento', 'salsa', 'vinagre', 'mayonesa'])) {
      return Icons.restaurant_outlined;
    }
    if (_any(s, ['almacen', 'grocery', 'seco', 'arroz', 'fideo', 'legumbre', 'yerba'])) {
      return Icons.kitchen_outlined;
    }
    if (_any(s, ['mascota', 'pet', 'alimento para'])) {
      return Icons.pets_outlined;
    }

    return null;
  }

  /// Convierte a minúsculas y elimina tildes para matching robusto.
  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  static bool _any(String normalized, List<String> keywords) =>
      keywords.any(normalized.contains);
}
