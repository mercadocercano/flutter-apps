import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/status_badge.dart';
import 'blocs/brand_form_bloc.dart';
import 'blocs/brands_bloc.dart';

class BrandDetailScreen extends StatefulWidget {
  final String brandId;
  final GetBrandUseCase getBrand;

  const BrandDetailScreen({
    super.key,
    required this.brandId,
    required this.getBrand,
  });

  @override
  State<BrandDetailScreen> createState() => _BrandDetailScreenState();
}

class _BrandDetailScreenState extends State<BrandDetailScreen> {
  MarketplaceBrand? _brand;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBrand();
  }

  Future<void> _loadBrand() async {
    try {
      final brand = await widget.getBrand.execute(widget.brandId);
      if (mounted) {
        setState(() {
          _brand = brand;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar la marca: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BrandFormBloc, BrandFormState>(
      listener: (context, state) {
        if (state is BrandFormSuccess) {
          if (state.entity != null) {
            setState(() => _brand = state.entity);
          }
          AdminSnackbars.showSuccess(context, 'Operacion realizada correctamente');
          context.read<BrandsBloc>().add(LoadBrandsEvent());
        } else if (state is BrandFormDeleted) {
          AdminSnackbars.showSuccess(context, 'Marca eliminada');
          context.go('/pim/brands');
        } else if (state is BrandFormError) {
          AdminSnackbars.showError(context, state.message);
        }
      },
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Marca')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: TextStyle(color: Colors.red[700])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadBrand,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final brand = _brand!;
    return _BrandDetailView(brand: brand);
  }
}

class _BrandDetailView extends StatelessWidget {
  final MarketplaceBrand brand;
  const _BrandDetailView({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(brand.name),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar'),
            onPressed: () =>
                context.push('/pim/brands/${brand.id}/edit'),
          ),
          TextButton.icon(
            icon: Icon(
              brand.isVerified
                  ? Icons.remove_moderator_outlined
                  : Icons.verified_user_outlined,
              size: 18,
            ),
            label: Text(brand.isVerified ? 'Desverificar' : 'Verificar'),
            onPressed: () => _toggleVerification(context),
          ),
          TextButton.icon(
            icon: Icon(Icons.delete_outline,
                size: 18, color: Colors.red[700]),
            label: Text('Eliminar',
                style: TextStyle(color: Colors.red[700])),
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
                if (brand.logoUrl != null) ...[
                  _LogoCard(logoUrl: brand.logoUrl!),
                  const SizedBox(height: 16),
                ],
                _ProductCountCard(count: brand.productCount),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Informacion General',
                  children: [
                    _InfoRow('ID', brand.id),
                    _InfoRow('Nombre', brand.name),
                    _InfoRow('Slug', brand.slug),
                    if (brand.normalizedName != null)
                      _InfoRow('Nombre normalizado', brand.normalizedName!),
                    if (brand.description != null)
                      _InfoRow('Descripcion', brand.description!),
                    if (brand.website != null)
                      _InfoRow('Sitio Web', brand.website!),
                    _InfoRow(
                      'Estado',
                      brand.isActive ? 'Activa' : 'Inactiva',
                      statusWidget: StatusBadge.fromString(
                        brand.isActive ? 'active' : 'inactive',
                        customLabel: brand.isActive ? 'Activa' : 'Inactiva',
                      ),
                    ),
                    _InfoRow(
                      'Verificacion',
                      brand.verificationStatus.toApiString(),
                    ),
                    _InfoRow(
                      'Calidad',
                      brand.qualityScore.toStringAsFixed(1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Visual',
                  children: [
                    if (brand.backgroundColor != null)
                      _InfoRow('Color de fondo', brand.backgroundColor!),
                    if (brand.textColor != null)
                      _InfoRow('Color de texto', brand.textColor!),
                    if (brand.typography != null)
                      _InfoRow('Tipografia', brand.typography!),
                  ],
                ),
                if (brand.categoryTags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _TagsCard(title: 'Categorias', tags: brand.categoryTags),
                ],
                if (brand.aliases.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _TagsCard(title: 'Aliases', tags: brand.aliases),
                ],
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Fechas',
                  children: [
                    _InfoRow('Creada', _formatDate(brand.createdAt)),
                    _InfoRow('Actualizada', _formatDate(brand.updatedAt)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _toggleVerification(BuildContext context) async {
    if (brand.isVerified) {
      context.read<BrandFormBloc>().add(UnverifyBrandFormEvent(brand.id));
    } else {
      context.read<BrandFormBloc>().add(VerifyBrandFormEvent(brand.id));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar Marca',
      message: '¿Eliminar "${brand.name}"? Esta accion no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<BrandFormBloc>().add(DeleteBrandFormEvent(brand.id));
    }
  }
}

class _ProductCountCard extends StatelessWidget {
  final int count;
  const _ProductCountCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Text('Productos asociados'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  final String logoUrl;
  const _LogoCard({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Image.network(
            logoUrl,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => const Icon(
              Icons.broken_image_outlined,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

class _TagsCard extends StatelessWidget {
  final String title;
  final List<String> tags;
  const _TagsCard({required this.title, required this.tags});

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
              children: tags
                  .map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
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
  final Widget? statusWidget;

  const _InfoRow(this.label, this.value, {this.statusWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
            child: statusWidget ??
                SelectableText(
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
