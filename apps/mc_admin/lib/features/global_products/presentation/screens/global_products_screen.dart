import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/global_product_model.dart';
import '../bloc/global_products_bloc.dart';

class GlobalProductsScreen extends StatefulWidget {
  const GlobalProductsScreen({super.key});

  @override
  State<GlobalProductsScreen> createState() => _GlobalProductsScreenState();
}

class _GlobalProductsScreenState extends State<GlobalProductsScreen> {
  final _searchController = TextEditingController();
  String? _filterBusinessType;
  bool? _filterVerified;
  bool? _filterHasImage;

  @override
  void initState() {
    super.initState();
    context.read<GlobalProductsBloc>()
      ..add(LoadBusinessTypesEvent())
      ..add(LoadGlobalProductsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<GlobalProductsBloc>().add(LoadGlobalProductsEvent(
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          businessType: _filterBusinessType,
          isVerified: _filterVerified,
          hasImage: _filterHasImage,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<GlobalProductsBloc, GlobalProductsState>(
        buildWhen: (previous, current) => current is! GlobalProductDetailLoaded,
        builder: (context, state) {
          if (state is GlobalProductsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GlobalProductsError) {
            return _buildError(state.message);
          }
          if (state is GlobalProductsLoaded) {
            return _buildContent(state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(GlobalProductsLoaded state) {
    final page = state.page;
    final businessTypes = state.allBusinessTypes.isNotEmpty
        ? state.allBusinessTypes
        : _extractBusinessTypes(page.items);

    // Sync state: if current filter no longer exists in results, clear it
    if (_filterBusinessType != null && !businessTypes.contains(_filterBusinessType)) {
      _filterBusinessType = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DataQualityBanner(page: page),
        _buildFilters(businessTypes),
        Expanded(
          child: page.items.isEmpty
              ? const Center(
                  child: Text(
                    'No hay productos con los filtros aplicados',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: page.items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _GlobalProductCard(product: page.items[index]),
                ),
        ),
      ],
    );
  }

  List<String> _extractBusinessTypes(List<GlobalProduct> items) {
    final types = items
        .map((p) => p.businessType)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    return types;
  }

  Widget _buildFilters(List<String> businessTypes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              DropdownButton<String?>(
                value: businessTypes.contains(_filterBusinessType) ? _filterBusinessType : null,
                hint: const Text('Tipo de comercio'),
                isDense: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...businessTypes.map(
                    (bt) => DropdownMenuItem<String?>(
                      value: bt,
                      child: Text(bt),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _filterBusinessType = value);
                  _applyFilters();
                },
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('Verificados'),
                selected: _filterVerified == true,
                onSelected: (v) {
                  setState(() => _filterVerified = v ? true : null);
                  _applyFilters();
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Con imagen'),
                selected: _filterHasImage == true,
                onSelected: (v) {
                  setState(() => _filterHasImage = v ? true : null);
                  _applyFilters();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _applyFilters,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

}

// ─── Banner de calidad de datos ───────────────────────────────────────────────

class _DataQualityBanner extends StatelessWidget {
  final GlobalProductsPage page;

  const _DataQualityBanner({required this.page});

  @override
  Widget build(BuildContext context) {
    final items = page.items;
    final withImage = items.where((p) => p.imageUrl != null).length;
    final withEan = items.where((p) => p.ean != null).length;
    final withDesc = items.where((p) => p.description != null).length;
    final total = page.totalCount;

    return Container(
      width: double.infinity,
      color: const Color(0xFFFEF9C3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        '$total productos · $withImage con imagen · $withEan con EAN · $withDesc con descripcion',
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF854D0E),
        ),
      ),
    );
  }
}

// ─── Card de producto ─────────────────────────────────────────────────────────

class _GlobalProductCard extends StatelessWidget {
  final GlobalProduct product;

  const _GlobalProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/global-products/${product.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _ProductThumbnail(imageUrl: product.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _QualityBadge(score: product.qualityScore),
                      ],
                    ),
                    if (product.brand != null || product.category != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (product.brand != null) product.brand!,
                          if (product.category != null) product.category!,
                        ].join(' · '),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (product.businessType != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.businessType!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.blueGrey),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (product.imageUrl == null)
                          _MissingDataChip(
                            label: 'SIN IMAGEN',
                            color: Colors.red,
                          ),
                        if (product.ean == null)
                          _MissingDataChip(
                            label: 'SIN EAN',
                            color: Colors.red,
                          ),
                        if (product.description == null)
                          _MissingDataChip(
                            label: 'SIN DESC',
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  final String? imageUrl;

  const _ProductThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Icon(
                  Icons.image_not_supported_outlined,
                  size: 24,
                  color: Colors.grey,
                ),
              )
            : const Icon(
                Icons.image_not_supported_outlined,
                size: 24,
                color: Colors.grey,
              ),
      ),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  final int score;

  const _QualityBadge({required this.score});

  Color get _color {
    if (score >= 70) return const Color(0xFF166534);
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MissingDataChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MissingDataChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 10)),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.08),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}
