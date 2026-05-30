import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_data_table.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/status_badge.dart';
import 'blocs/brand_form_bloc.dart';
import 'blocs/brands_bloc.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  BrandVerificationStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return BlocListener<BrandFormBloc, BrandFormState>(
      listener: (context, state) {
        if (state is BrandFormSuccess) {
          AdminSnackbars.showSuccess(context, 'Operacion realizada correctamente');
          context.read<BrandsBloc>().add(LoadBrandsEvent());
        } else if (state is BrandFormDeleted) {
          AdminSnackbars.showSuccess(context, 'Marca eliminada');
          context.read<BrandsBloc>().add(LoadBrandsEvent());
        } else if (state is BrandFormError) {
          AdminSnackbars.showError(context, state.message);
        }
      },
      child: BlocBuilder<BrandsBloc, BrandsState>(
        builder: (context, state) {
          final brands =
              state is BrandsLoaded ? state.brands : <MarketplaceBrand>[];
          final isLoading = state is BrandsLoading;
          final error = state is BrandsError ? state.message : null;
          final currentPage = state is BrandsLoaded ? state.currentPage : 1;
          final pageSize = state is BrandsLoaded ? state.pageSize : 20;
          final totalItems = state is BrandsLoaded ? state.totalItems : 0;

          return Column(
            children: [
              _FilterChips(
                selected: _filterStatus,
                onChanged: (status, isActive) {
                  setState(() => _filterStatus = status);
                  context.read<BrandsBloc>().add(LoadBrandsEvent(
                        verificationStatus: status,
                        isActive: isActive,
                      ));
                },
              ),
              Expanded(
                child: AdminDataTable<MarketplaceBrand>(
                  items: brands,
                  isLoading: isLoading,
                  error: error,
                  onRetry: () =>
                      context.read<BrandsBloc>().add(LoadBrandsEvent()),
                  currentPage: currentPage,
                  pageSize: pageSize,
                  totalItems: totalItems,
                  onPageChanged: (page) => context
                      .read<BrandsBloc>()
                      .add(ChangeBrandsPageEvent(page)),
                  searchHint: 'Buscar marca...',
                  onSearch: (query) => context
                      .read<BrandsBloc>()
                      .add(LoadBrandsEvent(
                        searchQuery: query.isEmpty ? null : query,
                        verificationStatus: _filterStatus,
                      )),
                  createLabel: 'Nueva Marca',
                  onCreateTap: () => context.push('/pim/brands/new'),
                  columns: [
                    AdminColumn<MarketplaceBrand>(
                      label: 'Logo',
                      width: 60,
                      builder: (item) => _BrandLogo(logoUrl: item.logoUrl),
                    ),
                    AdminColumn<MarketplaceBrand>(
                      label: 'Nombre',
                      builder: (item) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            item.slug,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    AdminColumn<MarketplaceBrand>(
                      label: 'Verificacion',
                      builder: (item) => _VerificationBadge(
                        status: item.verificationStatus,
                      ),
                    ),
                    AdminColumn<MarketplaceBrand>(
                      label: 'Productos',
                      builder: (item) => Text(
                        '${item.productCount}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    AdminColumn<MarketplaceBrand>(
                      label: 'Estado',
                      builder: (item) => StatusBadge.fromString(
                        item.isActive ? 'active' : 'inactive',
                        customLabel: item.isActive ? 'Activa' : 'Inactiva',
                      ),
                    ),
                    AdminColumn<MarketplaceBrand>(
                      label: 'Acciones',
                      builder: (item) => _RowActions(brand: item),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final BrandVerificationStatus? selected;
  final void Function(BrandVerificationStatus? status, bool? isActive) onChanged;

  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('Todas'),
            selected: selected == null,
            onSelected: (_) => onChanged(null, null),
          ),
          FilterChip(
            label: const Text('Verificadas'),
            selected: selected == BrandVerificationStatus.verified,
            onSelected: (_) =>
                onChanged(BrandVerificationStatus.verified, true),
          ),
          FilterChip(
            label: const Text('Sin verificar'),
            selected: selected == BrandVerificationStatus.unverified,
            onSelected: (_) =>
                onChanged(BrandVerificationStatus.unverified, true),
          ),
          FilterChip(
            label: const Text('Pendientes'),
            selected: selected == BrandVerificationStatus.pending,
            onSelected: (_) =>
                onChanged(BrandVerificationStatus.pending, true),
          ),
          FilterChip(
            label: const Text('Inactivas'),
            selected: selected == null,
            onSelected: (_) => onChanged(null, false),
          ),
        ],
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final String? logoUrl;
  const _BrandLogo({this.logoUrl});

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null || logoUrl!.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.image_outlined, size: 20, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        logoUrl!,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Container(
          width: 40,
          height: 40,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image_outlined, size: 20),
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final BrandVerificationStatus status;
  const _VerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BrandVerificationStatus.verified => ('Verificada', Colors.green),
      BrandVerificationStatus.pending => ('Pendiente', Colors.orange),
      BrandVerificationStatus.unverified => ('Sin verificar', Colors.grey),
    };

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withAlpha(26),
      side: BorderSide(color: color.withAlpha(77)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RowActions extends StatelessWidget {
  final MarketplaceBrand brand;
  const _RowActions({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 18),
          tooltip: 'Ver detalle',
          onPressed: () => context.push('/pim/brands/${brand.id}'),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Editar',
          onPressed: () => context.push('/pim/brands/${brand.id}/edit'),
        ),
        IconButton(
          icon: Icon(
            brand.isVerified
                ? Icons.verified_outlined
                : Icons.verified_user_outlined,
            size: 18,
            color: brand.isVerified ? Colors.orange : Colors.green,
          ),
          tooltip: brand.isVerified ? 'Desverificar' : 'Verificar',
          onPressed: () => _toggleVerification(context),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
          tooltip: 'Eliminar',
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
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
