import 'package:equatable/equatable.dart';

/// Resultado paginado genérico para listados del IAM (y otros dominios).
class PaginatedResult<T> extends Equatable {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items, totalCount, page, pageSize, totalPages];
}
