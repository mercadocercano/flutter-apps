import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/global_product_model.dart';
import '../bloc/global_products_bloc.dart';

class GlobalProductDetailScreen extends StatefulWidget {
  final String productId;

  const GlobalProductDetailScreen({super.key, required this.productId});

  @override
  State<GlobalProductDetailScreen> createState() =>
      _GlobalProductDetailScreenState();
}

class _GlobalProductDetailScreenState
    extends State<GlobalProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<GlobalProductsBloc>()
        .add(LoadGlobalProductDetailEvent(widget.productId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: BlocBuilder<GlobalProductsBloc, GlobalProductsState>(
        builder: (context, state) {
          if (state is GlobalProductsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GlobalProductsError) {
            return _buildError(context, state.message);
          }
          if (state is GlobalProductDetailLoaded) {
            return _buildDetail(context, state.product);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context
                .read<GlobalProductsBloc>()
                .add(LoadGlobalProductDetailEvent(widget.productId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, GlobalProduct product) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ImageSection(imageUrl: product.imageUrl),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Datos basicos',
            child: _BasicDataSection(product: product),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Calidad',
            child: _QualitySection(product: product),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Imagenes adicionales',
            child: _ImageUrlsSection(urls: product.imageUrls),
          ),
          if (product.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Etiquetas',
              child: _TagsSection(tags: product.tags),
            ),
          ],
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Fechas',
            child: _TimestampsSection(product: product),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Sección imagen principal ─────────────────────────────────────────────────

class _ImageSection extends StatelessWidget {
  final String? imageUrl;

  const _ImageSection({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _noImagePlaceholder(),
        ),
      );
    }
    return _noImagePlaceholder();
  }

  Widget _noImagePlaceholder() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text('Sin imagen', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Sección datos básicos ────────────────────────────────────────────────────

class _BasicDataSection extends StatelessWidget {
  final GlobalProduct product;

  const _BasicDataSection({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _DataRow(label: 'Marca', value: product.brand ?? '—'),
        _DataRow(label: 'Categoria', value: product.category ?? '—'),
        _DataRow(
          label: 'Tipo de comercio',
          value: product.businessType ?? '—',
        ),
        _DataRow(label: 'EAN', value: product.ean ?? 'Sin EAN'),
        _DataRow(
          label: 'Precio',
          value: product.price != null
              ? '\$${product.price!.toStringAsFixed(2)}'
              : 'Sin precio',
        ),
        _DataRow(label: 'Fuente', value: product.source),
        if (product.sourceUrl != null)
          _DataRow(label: 'URL fuente', value: product.sourceUrl!),
        if (product.description != null) ...[
          const SizedBox(height: 8),
          Text(
            'Descripcion',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(product.description!),
        ],
      ],
    );
  }
}

// ─── Sección calidad ──────────────────────────────────────────────────────────

class _QualitySection extends StatelessWidget {
  final GlobalProduct product;

  const _QualitySection({required this.product});

  @override
  Widget build(BuildContext context) {
    final score = product.qualityScore.clamp(0, 100);
    final scoreColor = score >= 70
        ? const Color(0xFF166534)
        : score >= 40
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Puntaje de calidad: $score / 100',
              style: TextStyle(fontWeight: FontWeight.w500, color: scoreColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatusChip(
              label: product.isVerified ? 'Verificado' : 'No verificado',
              color: product.isVerified
                  ? const Color(0xFF166534)
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            _StatusChip(
              label: product.isActive ? 'Activo' : 'Inactivo',
              color:
                  product.isActive ? const Color(0xFF166534) : Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _DataRow(
          label: 'Confiabilidad',
          value: '${(product.reliability * 100).toStringAsFixed(0)}%',
        ),
      ],
    );
  }
}

// ─── Sección URLs de imagen ───────────────────────────────────────────────────

class _ImageUrlsSection extends StatelessWidget {
  final List<String> urls;

  const _ImageUrlsSection({required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const Text(
        'Sin imagenes adicionales',
        style: TextStyle(color: Colors.grey),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: urls
          .map(
            (url) => ActionChip(
              label: Text(
                _truncateUrl(url),
                style: const TextStyle(fontSize: 11),
              ),
              avatar: const Icon(Icons.copy, size: 14),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL copiada al portapapeles'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          )
          .toList(),
    );
  }

  String _truncateUrl(String url) {
    if (url.length <= 40) return url;
    return '${url.substring(0, 20)}...${url.substring(url.length - 15)}';
  }
}

// ─── Sección tags ─────────────────────────────────────────────────────────────

class _TagsSection extends StatelessWidget {
  final List<String> tags;

  const _TagsSection({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tags
          .map(
            (tag) => Chip(
              label: Text(tag, style: const TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          )
          .toList(),
    );
  }
}

// ─── Sección timestamps ───────────────────────────────────────────────────────

class _TimestampsSection extends StatelessWidget {
  final GlobalProduct product;

  const _TimestampsSection({required this.product});

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DataRow(label: 'Creado', value: _formatDate(product.createdAt)),
        _DataRow(
          label: 'Actualizado',
          value: _formatDate(product.updatedAt),
        ),
      ],
    );
  }
}

// ─── Widgets compartidos ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.08),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}
