import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_design_system/mc_design_system.dart';

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
          const Icon(Icons.error_outline, size: 48, color: McColors.error),
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
          _ImageSection(
            imageUrl: product.imageUrl,
            onDeleteImage: product.imageUrl != null
                ? () => context
                    .read<GlobalProductsBloc>()
                    .add(ClearGlobalProductImageEvent(product.id))
                : null,
          ),
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
  final VoidCallback? onDeleteImage;

  const _ImageSection({this.imageUrl, this.onDeleteImage});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    if (hasImage) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => _noImagePlaceholder(),
            ),
          ),
          if (onDeleteImage != null)
            Positioned(
              top: 8,
              right: 8,
              child: _DeleteImageButton(onTap: onDeleteImage!),
            ),
        ],
      );
    }
    return _noImagePlaceholder();
  }

  Widget _noImagePlaceholder() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: McColors.mutedLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: McColors.borderLight),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: McColors.textSecondaryLight,
          ),
          SizedBox(height: 8),
          Text('Sin imagen', style: TextStyle(color: McColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _DeleteImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmDelete(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: McColors.error,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar imagen'),
        content: const Text('¿Eliminar la imagen asignada por webdata? No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: McColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) onTap();
    });
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
                ?.copyWith(color: McColors.textSecondaryLight),
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
        ? McColors.success
        : score >= 40
            ? McColors.warning
            : McColors.error;

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
          backgroundColor: McColors.borderLight,
          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatusChip(
              label: product.isVerified ? 'Verificado' : 'No verificado',
              color: product.isVerified ? McColors.success : McColors.textFg2,
            ),
            const SizedBox(width: 8),
            _StatusChip(
              label: product.isActive ? 'Activo' : 'Inactivo',
              color: product.isActive ? McColors.success : McColors.textFg2,
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
        style: TextStyle(color: McColors.textSecondaryLight),
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
                    color: McColors.textFg2,
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
                  ?.copyWith(color: McColors.textSecondaryLight),
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
