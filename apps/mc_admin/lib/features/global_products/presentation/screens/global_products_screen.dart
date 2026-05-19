import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_design_system/mc_design_system.dart';

import '../../domain/models/enrichment_result_model.dart';
import '../../domain/models/global_product_model.dart';
import '../bloc/global_products_bloc.dart';
import '../widgets/reject_image_dialog.dart';

const int _kMaxSelection = 100;

class GlobalProductsScreen extends StatefulWidget {
  const GlobalProductsScreen({super.key});

  @override
  State<GlobalProductsScreen> createState() => _GlobalProductsScreenState();
}

class _GlobalProductsScreenState extends State<GlobalProductsScreen> {
  final _searchController = TextEditingController();
  final _btScrollCtrl = ScrollController();
  String? _filterBusinessType;
  bool? _filterVerified;
  bool? _filterHasImage;

  bool _canScrollBtLeft = false;
  bool _canScrollBtRight = true;

  @override
  void initState() {
    super.initState();
    _btScrollCtrl.addListener(_onBtScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_btScrollCtrl.hasClients) _onBtScroll();
      });
    });
    context.read<GlobalProductsBloc>()
      ..add(LoadBusinessTypesEvent())
      ..add(LoadGlobalProductsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _btScrollCtrl.dispose();
    super.dispose();
  }

  void _onBtScroll() {
    final pos = _btScrollCtrl.position;
    setState(() {
      _canScrollBtLeft = pos.pixels > 4;
      _canScrollBtRight = pos.pixels < pos.maxScrollExtent - 4;
    });
  }

  void _scrollBt(double delta) {
    _btScrollCtrl.animateTo(
      (_btScrollCtrl.offset + delta)
          .clamp(0, _btScrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
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

  void _toggleSelection(String id) {
    context.read<GlobalProductsBloc>().add(ToggleProductSelectionEvent(id));
  }

  void _toggleSelectAll(List<GlobalProduct> items) {
    final ids = items.map((p) => p.id).toList();
    context.read<GlobalProductsBloc>().add(SelectAllProductsEvent(ids));
  }

  void _clearSelection() {
    context.read<GlobalProductsBloc>().add(ClearSelectionEvent());
  }

  Future<void> _confirmAndRejectImage(
    BuildContext context,
    String productId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const RejectImageDialog(),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    context.read<GlobalProductsBloc>().add(RejectProductImageEvent(productId));
  }

  Future<void> _confirmAndEnrich(
    BuildContext context,
    List<String> selectedIds,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _EnrichConfirmDialog(count: selectedIds.length),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    context.read<GlobalProductsBloc>().add(
          RunEnrichmentEvent(productIds: selectedIds),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: McColors.backgroundLight,
      body: BlocConsumer<GlobalProductsBloc, GlobalProductsState>(
        listenWhen: (_, current) =>
            current is EnrichmentSuccess ||
            current is EnrichmentError ||
            current is RejectImageSuccess ||
            current is RejectImageError,
        listener: (context, state) {
          if (state is EnrichmentSuccess) {
            _showEnrichmentResult(context, state.result);
          } else if (state is EnrichmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: McColors.error,
              ),
            );
            context.read<GlobalProductsBloc>().add(DismissEnrichmentResultEvent());
          } else if (state is RejectImageSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Imagen rechazada. Se buscará una nueva en el próximo enriquecimiento.'),
                backgroundColor: McColors.success,
              ),
            );
          } else if (state is RejectImageError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: McColors.error,
              ),
            );
          }
        },
        buildWhen: (previous, current) =>
            current is! GlobalProductDetailLoaded &&
            current is! EnrichmentSuccess &&
            current is! EnrichmentError &&
            current is! RejectImageSuccess &&
            current is! RejectImageError,
        builder: (context, state) {
          if (state is EnrichmentRunning) {
            return _buildEnrichingOverlay();
          }
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

  void _showEnrichmentResult(BuildContext context, EnrichmentResult result) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _EnrichResultDialog(result: result),
    ).then((_) {
      if (context.mounted) {
        context.read<GlobalProductsBloc>().add(DismissEnrichmentResultEvent());
      }
    });
  }

  Widget _buildEnrichingOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Enriqueciendo con IA...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: McColors.foregroundLight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esto puede tardar unos segundos',
            style: TextStyle(
              fontSize: 13,
              color: McColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(GlobalProductsLoaded state) {
    final page = state.page;
    final businessTypes = state.allBusinessTypes.isNotEmpty
        ? state.allBusinessTypes
        : _extractBusinessTypes(page.items);

    if (_filterBusinessType != null &&
        !businessTypes.contains(_filterBusinessType)) {
      _filterBusinessType = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearch(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              McSpacing.base, 4, McSpacing.base, 0),
          child: Row(
            children: [
              Text(
                '${page.totalCount} productos',
                style: const TextStyle(
                  fontSize: 12,
                  color: McColors.textSecondaryLight,
                ),
              ),
              const Spacer(),
              _buildEnrichBar(state, page.items),
            ],
          ),
        ),
        _buildStatusChips(),
        _buildBtChips(businessTypes),
        const SizedBox(height: McSpacing.sm),
        Expanded(
          child: page.items.isEmpty
              ? const Center(
                  child: Text(
                    'No hay productos con los filtros aplicados',
                    style: TextStyle(color: McColors.textSecondaryLight),
                  ),
                )
              : _buildGrid(page.items, state.selectedIds),
        ),
      ],
    );
  }

  /// Barra de acción de enriquecimiento (seleccionar todo + botón enriquecer)
  Widget _buildEnrichBar(GlobalProductsLoaded state, List<GlobalProduct> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    final allIds = items.map((p) => p.id).toList();
    final allSelected =
        allIds.isNotEmpty && allIds.every((id) => state.selectedIds.contains(id));
    final selectedCount = state.selectedIds.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.hasSelection)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Cancelar selección',
              child: GestureDetector(
                onTap: _clearSelection,
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: McColors.textSecondaryLight,
                ),
              ),
            ),
          ),
        Tooltip(
          message: allSelected ? 'Deseleccionar todos' : 'Seleccionar todos (máx $_kMaxSelection)',
          child: GestureDetector(
            onTap: () => _toggleSelectAll(items),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: allSelected
                    ? McColors.primary.withValues(alpha: 0.1)
                    : Colors.white,
                border: Border.all(
                  color: allSelected
                      ? McColors.primary
                      : McColors.borderLight,
                ),
                borderRadius:
                    BorderRadius.circular(McSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    allSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 14,
                    color: allSelected
                        ? McColors.primary
                        : McColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    allSelected ? 'Todos' : 'Seleccionar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: allSelected
                          ? McColors.primary
                          : McColors.textFg2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state.hasSelection) ...[
          const SizedBox(width: 8),
          McButton(
            label: 'Enriquecer ($selectedCount)',
            icon: Icons.auto_awesome,
            size: McButtonSize.sm,
            onPressed: () => _confirmAndEnrich(
              context,
              state.selectedIds.toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          McSpacing.base, McSpacing.md, McSpacing.base, 0),
      child: McTextField(
        hint: 'Buscar producto...',
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

  Widget _buildStatusChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
          McSpacing.base, McSpacing.sm, McSpacing.base, 0),
      child: Row(
        children: [
          _AdminChip(
            label: 'Verificados',
            isSelected: _filterVerified == true,
            onTap: () {
              setState(
                  () => _filterVerified = _filterVerified == true ? null : true);
              _applyFilters();
            },
          ),
          const SizedBox(width: McSpacing.sm),
          _AdminChip(
            label: 'Con imagen',
            isSelected: _filterHasImage == true,
            onTap: () {
              setState(() =>
                  _filterHasImage = _filterHasImage == true ? null : true);
              _applyFilters();
            },
          ),
          const SizedBox(width: McSpacing.sm),
          _AdminChip(
            label: 'Sin imagen',
            isSelected: _filterHasImage == false,
            onTap: () {
              setState(() =>
                  _filterHasImage = _filterHasImage == false ? null : false);
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBtChips(List<String> businessTypes) {
    if (businessTypes.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: _canScrollBtLeft ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: _ArrowBtn(
              icon: Icons.chevron_left,
              onTap: _canScrollBtLeft ? () => _scrollBt(-200) : null,
            ),
          ),
          Expanded(
            child: ListView(
              controller: _btScrollCtrl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: McSpacing.sm, vertical: 4),
              children: [
                _AdminChip(
                  label: 'Todos los rubros',
                  isSelected: _filterBusinessType == null,
                  onTap: () {
                    setState(() => _filterBusinessType = null);
                    _applyFilters();
                  },
                ),
                ...businessTypes.map((bt) => Padding(
                      padding: const EdgeInsets.only(left: McSpacing.sm),
                      child: _AdminChip(
                        label: bt,
                        isSelected: _filterBusinessType == bt,
                        onTap: () {
                          setState(() => _filterBusinessType = bt);
                          _applyFilters();
                        },
                      ),
                    )),
              ],
            ),
          ),
          AnimatedOpacity(
            opacity: _canScrollBtRight ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: _ArrowBtn(
              icon: Icons.chevron_right,
              onTap: _canScrollBtRight ? () => _scrollBt(200) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<GlobalProduct> items, Set<String> selectedIds) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: McSpacing.base),
          sliver: SliverLayoutBuilder(
            builder: (_, constraints) {
              final w = constraints.crossAxisExtent;
              final cols = w < 400
                  ? 3
                  : w < 700
                      ? 5
                      : w < 1000
                          ? 7
                          : 9;
              return SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _GlobalProductCard(
                    product: items[i],
                    isSelected: selectedIds.contains(items[i].id),
                    onTap: () => _toggleSelection(items[i].id),
                    onCardTap: selectedIds.isNotEmpty
                        ? () => _toggleSelection(items[i].id)
                        : () => context.push('/global-products/${items[i].id}'),
                    onRejectImage: () => _confirmAndRejectImage(
                      context,
                      items[i].id,
                    ),
                  ),
                  childCount: items.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: 0.50,
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

  List<String> _extractBusinessTypes(List<GlobalProduct> items) {
    return items
        .map((p) => p.businessType)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: McColors.error),
          const SizedBox(height: McSpacing.md),
          Text(message, textAlign: TextAlign.center),
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
}

// ─── Dialog de confirmación de enrichment ──────────────────────────────────

class _EnrichConfirmDialog extends StatelessWidget {
  final int count;

  const _EnrichConfirmDialog({required this.count});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: McColors.primary, size: 22),
          const SizedBox(width: 8),
          const Text('Enriquecer con IA'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Se procesarán $count producto${count == 1 ? '' : 's'}.',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: McColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: McColors.warning.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card_outlined,
                    size: 16, color: McColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esto consume créditos de Firecrawl.',
                    style: TextStyle(
                      fontSize: 12,
                      color: McColors.warning.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        McButton(
          label: 'Confirmar',
          icon: Icons.auto_awesome,
          size: McButtonSize.sm,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

// ─── Dialog de resultado de enrichment ────────────────────────────────────

class _EnrichResultDialog extends StatefulWidget {
  final EnrichmentResult result;

  const _EnrichResultDialog({required this.result});

  @override
  State<_EnrichResultDialog> createState() => _EnrichResultDialogState();
}

class _EnrichResultDialogState extends State<_EnrichResultDialog> {
  bool _showErrors = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            result.failed > 0 ? Icons.warning_amber : Icons.check_circle,
            color: result.failed > 0 ? McColors.warning : McColors.success,
            size: 22,
          ),
          const SizedBox(width: 8),
          const Text('Resultado del enrichment'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ResultRow(
            icon: Icons.check_circle_outline,
            color: McColors.success,
            label: 'Procesados',
            value: '${result.processed}',
          ),
          const SizedBox(height: 8),
          _ResultRow(
            icon: Icons.skip_next_outlined,
            color: McColors.textSecondaryLight,
            label: 'Saltados',
            value: '${result.skipped}',
          ),
          if (result.failed > 0) ...[
            const SizedBox(height: 8),
            _ResultRow(
              icon: Icons.error_outline,
              color: McColors.error,
              label: 'Fallidos',
              value: '${result.failed}',
            ),
          ],
          const Divider(height: 24),
          _ResultRow(
            icon: Icons.credit_card_outlined,
            color: McColors.primary,
            label: 'Costo',
            value: result.formattedCost,
          ),
          if (result.hasErrors) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _showErrors = !_showErrors),
              child: Row(
                children: [
                  Icon(
                    _showErrors ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: McColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${result.errors.length} error${result.errors.length == 1 ? '' : 'es'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: McColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_showErrors) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: McColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: McColors.error.withValues(alpha: 0.2)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: result.errors.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${result.errors[i]}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: McColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _ResultRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: McColors.textFg2),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Card de producto global ───────────────────────────────────────────────

class _GlobalProductCard extends StatelessWidget {
  final GlobalProduct product;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onCardTap;

  /// Callback para rechazar la imagen activa del producto.
  /// Solo se invoca cuando el producto tiene imagen.
  final VoidCallback onRejectImage;

  const _GlobalProductCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
    required this.onCardTap,
    required this.onRejectImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onCardTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? McColors.primary.withValues(alpha: 0.06)
              : Colors.white,
          border: Border.all(
            color: isSelected ? McColors.primary : McColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen + badges
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: McColors.mutedLight,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(McSpacing.radiusLg - 1),
                  ),
                ),
                child: Stack(
                  children: [
                    // Imagen real o fallback cobalt
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (_, constraints) => ProductImageWidget(
                          imageUrl: product.imageUrl,
                          category: product.category,
                          businessType: product.businessType,
                          size: constraints.maxWidth,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(McSpacing.radiusLg - 1),
                          ),
                        ),
                      ),
                    ),

                    // Badge de calidad (top-right) — siempre visible
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _QualityBadge(score: product.qualityScore),
                    ),

                    // Badge "SIN IMG" (top-left) — solo si no hay imagen
                    if (!hasImage)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _SmallBadge('SIN IMG', McColors.error),
                      ),

                    // Botón rechazar imagen (top-right) — solo si hay imagen
                    if (hasImage)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Tooltip(
                          message: 'Rechazar imagen',
                          child: GestureDetector(
                            onTap: onRejectImage,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: McColors.error.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Checkbox de selección (bottom-right)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Tooltip(
                        message: isSelected ? 'Deseleccionar' : 'Seleccionar para enriquecer',
                        child: GestureDetector(
                          onTap: onTap,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? McColors.primary
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? McColors.primary
                                    : McColors.borderLight,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),

                    // Badge de enrichment status (bottom-left)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Tooltip(
                        message: hasImage ? 'Enriquecido' : 'Sin enriquecer',
                        child: Icon(
                          hasImage
                              ? Icons.auto_awesome
                              : Icons.auto_awesome_outlined,
                          size: 14,
                          color: hasImage
                              ? McColors.success
                              : McColors.textSecondaryLight.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: McColors.foregroundLight,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.brand != null || product.category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (product.brand != null) product.brand!,
                          if (product.category != null) product.category!,
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 10,
                          color: McColors.textFg2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (product.businessType != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.businessType!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: McColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        if (product.ean == null)
                          _SmallBadge('SIN EAN', McColors.error),
                        if (product.description == null)
                          _SmallBadge('SIN DESC', McColors.warning),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge de calidad ─────────────────────────────────────────────────────

class _QualityBadge extends StatelessWidget {
  final int score;

  const _QualityBadge({required this.score});

  Color get _color {
    if (score >= 70) return McColors.success;
    if (score >= 40) return McColors.warning;
    return McColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(McSpacing.radiusSm),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Badge pequeño ────────────────────────────────────────────────────────

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Chip de filtro ──────────────────────────────────────────────────────

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

// ─── Flecha de scroll ────────────────────────────────────────────────────

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ArrowBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: McColors.borderLight),
          borderRadius: BorderRadius.circular(McSpacing.radiusFull),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14050C40),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: McColors.textFg2),
      ),
    );
  }
}
