import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_design_system/mc_design_system.dart';

import '../../domain/models/brand_model.dart';
import '../bloc/brands_bloc.dart';
import '../../../../shared/widgets/admin_modal.dart';

class BrandsListScreen extends StatefulWidget {
  const BrandsListScreen({super.key});

  @override
  State<BrandsListScreen> createState() => _BrandsListScreenState();
}

class _BrandsListScreenState extends State<BrandsListScreen> {
  final _searchController = TextEditingController();
  bool? _filterVerified;
  bool? _filterActive;

  @override
  void initState() {
    super.initState();
    context.read<BrandsBloc>().add(LoadBrandsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<BrandsBloc>().add(LoadBrandsEvent(
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          verified: _filterVerified,
          active: _filterActive,
        ));
  }

  Future<void> _confirmDelete(BuildContext context, Brand brand) async {
    final confirmed = await showAdminConfirm(
      context: context,
      title: 'Eliminar marca',
      message: '¿Eliminar "${brand.name}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      confirmColor: McColors.error,
    );
    if (confirmed && context.mounted) {
      context.read<BrandsBloc>().add(DeleteBrandEvent(brand.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: McColors.backgroundLight,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/brands/new'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildSearch(),
          _buildFilterChips(),
          const SizedBox(height: McSpacing.sm),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          McSpacing.base, McSpacing.md, McSpacing.base, 0),
      child: McTextField(
        hint: 'Buscar marca...',
        controller: _searchController,
        prefixIcon: Icons.search,
        onChanged: (v) {
          if (v.isEmpty) _applyFilters();
        },
        suffix: IconButton(
          icon: const Icon(Icons.search, size: 18),
          onPressed: _applyFilters,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
          McSpacing.base, McSpacing.sm, McSpacing.base, 0),
      child: Row(
        children: [
          _AdminChip(
            label: 'Verificadas',
            isSelected: _filterVerified == true,
            onTap: () {
              setState(() =>
                  _filterVerified = _filterVerified == true ? null : true);
              _applyFilters();
            },
          ),
          const SizedBox(width: McSpacing.sm),
          _AdminChip(
            label: 'Sin verificar',
            isSelected: _filterVerified == false,
            onTap: () {
              setState(() =>
                  _filterVerified = _filterVerified == false ? null : false);
              _applyFilters();
            },
          ),
          const SizedBox(width: McSpacing.sm),
          _AdminChip(
            label: 'Activas',
            isSelected: _filterActive == true,
            onTap: () {
              setState(
                  () => _filterActive = _filterActive == true ? null : true);
              _applyFilters();
            },
          ),
          const SizedBox(width: McSpacing.sm),
          _AdminChip(
            label: 'Inactivas',
            isSelected: _filterActive == false,
            onTap: () {
              setState(
                  () => _filterActive = _filterActive == false ? null : false);
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<BrandsBloc, BrandsState>(
      builder: (context, state) {
        if (state is BrandsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is BrandsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: McColors.error),
                const SizedBox(height: McSpacing.md),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: McSpacing.base),
                FilledButton.icon(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        if (state is BrandsLoaded) {
          if (state.brands.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.branding_watermark_outlined,
                      size: 64, color: McColors.textSecondaryLight),
                  const SizedBox(height: McSpacing.base),
                  const Text('No hay marcas',
                      style: TextStyle(color: McColors.textSecondaryLight)),
                ],
              ),
            );
          }
          return _buildGrid(state.brands);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGrid(List<Brand> brands) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: McSpacing.base),
          sliver: SliverLayoutBuilder(
            builder: (_, constraints) {
              final w = constraints.crossAxisExtent;
              final cols = w < 400
                  ? 4
                  : w < 700
                      ? 6
                      : w < 1000
                          ? 8
                          : 10;
              return SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _BrandCard(
                    brand: brands[i],
                    onDelete: _confirmDelete,
                  ),
                  childCount: brands.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: McSpacing.sm,
                  mainAxisSpacing: McSpacing.sm,
                ),
              );
            },
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }
}

// ─── Card de marca ───

class _BrandCard extends StatelessWidget {
  final Brand brand;
  final Future<void> Function(BuildContext, Brand) onDelete;

  const _BrandCard({required this.brand, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final palette = McBrandPalette.fromBrandDto(
      backgroundHex: brand.backgroundColor,
      textHex: brand.textColor,
      fontFamily: brand.typography,
      brightness: brightness,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: McColors.borderLight),
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. PREVIEW de marca (AspectRatio 1:1, fondo del color de marca)
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: palette.backgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(McSpacing.radiusLg - 1),
                ),
              ),
              child: brand.logoUrl != null
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.network(
                        brand.logoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            _BrandInitial(name: brand.name, palette: palette),
                      ),
                    )
                  : _BrandInitial(name: brand.name, palette: palette),
            ),
          ),

          // 2. INFO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.name,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: McColors.foregroundLight,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Status chips
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      _StatusBadge(
                        label: brand.verificationStatus
                            ? 'Verificada'
                            : 'Sin verificar',
                        color: brand.verificationStatus
                            ? McColors.success
                            : McColors.textFg2,
                      ),
                      _StatusBadge(
                        label: brand.isActive ? 'Activa' : 'Inactiva',
                        color: brand.isActive
                            ? McColors.success
                            : McColors.error,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Acciones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!brand.verificationStatus)
                        _ActionIcon(
                          icon: Icons.verified_outlined,
                          tooltip: 'Verificar',
                          color: McColors.primary,
                          onTap: () => context
                              .read<BrandsBloc>()
                              .add(VerifyBrandEvent(brand.id)),
                        ),
                      _ActionIcon(
                        icon: Icons.edit_outlined,
                        tooltip: 'Editar',
                        color: McColors.textFg2,
                        onTap: () => context.push('/brands/${brand.id}/edit'),
                      ),
                      _ActionIcon(
                        icon: Icons.delete_outline,
                        tooltip: 'Eliminar',
                        color: McColors.error,
                        onTap: () => onDelete(context, brand),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Inicial de marca ───

class _BrandInitial extends StatelessWidget {
  final String name;
  final McBrandPalette palette;

  const _BrandInitial({required this.name, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          name,
          style: TextStyle(
            color: palette.textColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ─── Badge de estado ───

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Icono de acción ───

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(McSpacing.radiusSm),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─── Chip de filtro ───

class _AdminChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdminChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? McColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(McSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? McColors.primary : McColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: isSelected ? Colors.white : McColors.textFg2,
          ),
        ),
      ),
    );
  }
}
