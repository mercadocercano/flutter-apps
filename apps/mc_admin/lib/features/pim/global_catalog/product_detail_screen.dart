import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'blocs/product_form_bloc.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductFormBloc>().add(LoadProductEvent(widget.productId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductFormBloc, ProductFormState>(
      listener: _onStateChange,
      child: BlocBuilder<ProductFormBloc, ProductFormState>(
        builder: (context, state) {
          if (state is ProductFormLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ProductFormError) {
            return _ErrorScaffold(
              message: state.message,
              onRetry: () => context
                  .read<ProductFormBloc>()
                  .add(LoadProductEvent(widget.productId)),
            );
          }

          if (state is ProductFormLoaded) {
            return _DetailView(product: state.product);
          }

          if (state is ProductFormSubmitting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  void _onStateChange(BuildContext context, ProductFormState state) {
    if (state is ProductFormSuccess && state.product != null) {
      AdminSnackbars.showSuccess(context, 'Operación realizada correctamente');
      // Recargar producto para reflejar cambios
      context
          .read<ProductFormBloc>()
          .add(LoadProductEvent(widget.productId));
    } else if (state is ProductFormDeleted) {
      AdminSnackbars.showSuccess(context, 'Producto eliminado');
      context.go('/pim/global-catalog');
    } else if (state is ProductFormError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de producto')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final GlobalProduct product;

  const _DetailView({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar'),
            onPressed: () =>
                context.push('/pim/global-catalog/${product.id}/edit'),
          ),
          TextButton.icon(
            icon: Icon(
              product.isVerified
                  ? Icons.remove_moderator_outlined
                  : Icons.verified_user_outlined,
              size: 18,
            ),
            label: Text(
                product.isVerified ? 'Desverificar' : 'Verificar'),
            onPressed: () => _toggleVerification(context),
          ),
          TextButton.icon(
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: Colors.red[700],
            ),
            label: Text(
              'Eliminar',
              style: TextStyle(color: Colors.red[700]),
            ),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.imageUrl != null) ...[
                  _ImageCard(imageUrl: product.imageUrl!),
                  const SizedBox(height: 16),
                ],
                _InfoCard(
                  title: 'Información general',
                  children: [
                    _InfoRow('ID', product.id),
                    _InfoRow('Nombre', product.name),
                    _InfoRow('SKU', product.sku),
                    _InfoRow('Barcode', product.barcode ?? '—'),
                    if (product.description != null)
                      _InfoRow('Descripción', product.description!),
                    _InfoRow(
                      'Categoría',
                      product.categoryId ?? '—',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Estado',
                  children: [
                    _InfoRowWithWidget(
                      label: 'Verificado',
                      child: _VerifiedChip(isVerified: product.isVerified),
                    ),
                    if (product.verifiedAt != null)
                      _InfoRow(
                        'Verificado el',
                        _formatDate(product.verifiedAt!),
                      ),
                  ],
                ),
                if (product.businessTypeIds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ChipsCard(
                    title: 'Tipos de comercio',
                    chips: product.businessTypeIds,
                  ),
                ],
                if (product.attributes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _AttributesCard(attributes: product.attributes),
                ],
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Fechas',
                  children: [
                    _InfoRow('Creado', _formatDate(product.createdAt)),
                    _InfoRow(
                        'Actualizado', _formatDate(product.updatedAt)),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _toggleVerification(BuildContext context) async {
    if (product.isVerified) {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Desverificar producto',
        message: '¿Quitar la verificación de "${product.name}"?',
        confirmLabel: 'Desverificar',
        isDangerous: true,
      );
      if (confirmed == true && context.mounted) {
        context
            .read<ProductFormBloc>()
            .add(UnverifyProductEvent(product.id));
      }
    } else {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Verificar producto',
        message: '¿Verificar "${product.name}"?',
        confirmLabel: 'Verificar',
      );
      if (confirmed == true && context.mounted) {
        context
            .read<ProductFormBloc>()
            .add(VerifyProductEvent(product.id));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar producto',
      message:
          '¿Eliminar "${product.name}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context
          .read<ProductFormBloc>()
          .add(DeleteProductEvent(product.id));
    }
  }
}

// --- Widgets de detalle ---

class _VerifiedChip extends StatelessWidget {
  final bool isVerified;

  const _VerifiedChip({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        isVerified ? 'Verificado' : 'Sin verificar',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor:
          (isVerified ? Colors.green : Colors.grey).withAlpha(26),
      side: BorderSide(
        color: (isVerified ? Colors.green : Colors.grey).withAlpha(77),
      ),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String imageUrl;

  const _ImageCard({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Image.network(
            imageUrl,
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => const Icon(
              Icons.broken_image_outlined,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

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
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRowWithWidget extends StatelessWidget {
  final String label;
  final Widget child;

  const _InfoRowWithWidget({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ChipsCard extends StatelessWidget {
  final String title;
  final List<String> chips;

  const _ChipsCard({required this.title, required this.chips});

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
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Divider(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: chips
                  .map(
                    (c) => Chip(
                      label: Text(c,
                          style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributesCard extends StatelessWidget {
  final Map<String, dynamic> attributes;

  const _AttributesCard({required this.attributes});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Atributos',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Divider(height: 16),
            ...attributes.entries.map(
              (e) => _InfoRow(e.key, e.value?.toString() ?? '—'),
            ),
          ],
        ),
      ),
    );
  }
}
