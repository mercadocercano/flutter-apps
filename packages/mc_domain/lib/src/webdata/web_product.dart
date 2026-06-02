import 'package:equatable/equatable.dart';

import 'price_point.dart';

/// Producto scrapeado desde una fuente web externa.
///
/// Representa un producto tal como fue extraído del sitio origen.
/// Puede estar asignado a un business_type para integrarse al catálogo.
class WebProduct extends Equatable {
  final String id;
  final String sourceId;
  final String name;
  final double price;
  final String? imageUrl;
  final String url;

  /// Business type asignado. Null si aún no fue clasificado.
  final String? businessTypeId;

  final DateTime scrapedAt;

  /// Historial de precios ordenado cronológicamente.
  final List<PricePoint> priceHistory;

  const WebProduct({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.url,
    this.businessTypeId,
    required this.scrapedAt,
    this.priceHistory = const [],
  });

  /// Indica si el producto ya fue asignado a un tipo de comercio.
  bool get hasBusinessType => businessTypeId != null;

  WebProduct copyWith({
    String? id,
    String? sourceId,
    String? name,
    double? price,
    String? imageUrl,
    String? url,
    String? businessTypeId,
    DateTime? scrapedAt,
    List<PricePoint>? priceHistory,
  }) {
    return WebProduct(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      url: url ?? this.url,
      businessTypeId: businessTypeId ?? this.businessTypeId,
      scrapedAt: scrapedAt ?? this.scrapedAt,
      priceHistory: priceHistory ?? this.priceHistory,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sourceId,
        name,
        price,
        imageUrl,
        url,
        businessTypeId,
        scrapedAt,
        priceHistory,
      ];
}
