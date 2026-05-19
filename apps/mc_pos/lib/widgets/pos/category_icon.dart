import 'package:flutter/material.dart';

/// Retorna un [IconData] representativo según el nombre de categoría del producto.
/// Fallback: [Icons.inventory_2_outlined].
IconData categoryIconFor(String? categoryName) {
  if (categoryName == null) return Icons.inventory_2_outlined;
  final cat = categoryName.toLowerCase();

  if (_any(cat, ['bebida', 'gaseosa', 'jugo', 'agua', 'refresco', 'soda'])) {
    return Icons.local_drink_outlined;
  }
  if (_any(cat, ['cerveza'])) return Icons.sports_bar_outlined;
  if (_any(cat, ['vino', 'licor', 'fernet', 'whisky', 'vodka', 'bebida alc'])) {
    return Icons.wine_bar_outlined;
  }
  if (_any(cat, ['lácteo', 'lacteo', 'leche', 'yogur', 'queso', 'manteca', 'crema'])) {
    return Icons.egg_alt_outlined;
  }
  if (_any(cat, ['carne', 'pollo', 'pescado', 'mariscos'])) {
    return Icons.set_meal_outlined;
  }
  if (_any(cat, ['pan', 'panadería', 'panaderia', 'galletita', 'facturas'])) {
    return Icons.bakery_dining_outlined;
  }
  if (_any(cat, ['fruta', 'verdura', 'vegetal', 'hortal'])) {
    return Icons.eco_outlined;
  }
  if (_any(cat, ['limpieza', 'detergente', 'lavandina', 'jabón', 'jabon'])) {
    return Icons.cleaning_services_outlined;
  }
  if (_any(cat, ['higiene', 'perfume', 'cosmético', 'cosmetico', 'shampoo', 'desodorante'])) {
    return Icons.soap_outlined;
  }
  if (_any(cat, ['golosina', 'chocolate', 'caramelo', 'alfajor', 'candy'])) {
    return Icons.cake_outlined;
  }
  if (_any(cat, ['snack', 'papa', 'chips', 'maní', 'mani'])) {
    return Icons.fastfood_outlined;
  }
  if (_any(cat, ['electrónica', 'electronica', 'celular', 'tecnología', 'tecnologia', 'electrodoméstico'])) {
    return Icons.devices_outlined;
  }
  if (_any(cat, ['ferretería', 'ferreteria', 'herramienta', 'tornillo', 'pintura'])) {
    return Icons.hardware_outlined;
  }
  if (_any(cat, ['papelería', 'papeleria', 'librería', 'libreria', 'cuaderno'])) {
    return Icons.auto_stories_outlined;
  }
  if (_any(cat, ['ropa', 'indumentaria', 'calzado', 'textil'])) {
    return Icons.checkroom_outlined;
  }
  if (_any(cat, ['medicamento', 'farmacia', 'remedio', 'vitamina'])) {
    return Icons.medical_services_outlined;
  }
  if (_any(cat, ['congelado', 'helado', 'frozen'])) {
    return Icons.ac_unit_outlined;
  }
  if (_any(cat, ['aceite', 'condimento', 'salsa', 'vinagre', 'mayonesa'])) {
    return Icons.restaurant_outlined;
  }
  if (_any(cat, ['almacén', 'almacen', 'seco', 'arroz', 'fideo', 'legumbre', 'harina', 'yerba', 'café'])) {
    return Icons.kitchen_outlined;
  }
  if (_any(cat, ['mascota', 'alimento para'])) {
    return Icons.pets_outlined;
  }

  return Icons.inventory_2_outlined;
}

bool _any(String category, List<String> keywords) =>
    keywords.any(category.contains);
