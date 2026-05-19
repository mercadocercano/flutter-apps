import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import '../quickstart/brand_badge.dart';
import '../../widgets/pos/pos_modal.dart';

/// Pantalla de gestión de marcas — grid con buscador e infinite scroll.
class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  static const _pageSize = 20;

  List<Brand> _brands = [];
  int _currentPage = 1;
  int _totalCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String _query = '';

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadPage(1);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadPage(int page) async {
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _error = null;
        _brands = [];
      });
    }
    try {
      final port = context.read<BrandPort>();
      final result = await port.listBrands(page: page, pageSize: _pageSize);
      if (mounted) {
        setState(() {
          if (page == 1) {
            _brands = result.items;
          } else {
            _brands = [..._brands, ...result.items];
          }
          _currentPage = page;
          _totalCount = result.totalCount;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No pudimos cargar las marcas. Verificá tu conexión.';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    final hasMore = _currentPage * _pageSize < _totalCount;
    if (!hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await _loadPage(_currentPage + 1);
  }

  Future<void> _refresh() => _loadPage(1);

  List<Brand> get _filtered {
    if (_query.isEmpty) return _brands;
    return _brands.where((b) => b.name.toLowerCase().contains(_query)).toList();
  }

  bool get _hasMore => _currentPage * _pageSize < _totalCount;

  Future<void> _showForm({Brand? editing}) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final descCtrl = TextEditingController(text: editing?.description ?? '');
    final confirmed = await showPosDialog<bool>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(McSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editing == null ? 'Nueva marca' : 'Editar marca',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: McColors.foregroundLight,
              ),
            ),
            const SizedBox(height: McSpacing.md),
            McTextField(controller: nameCtrl, hint: 'Nombre *', autofocus: true),
            const SizedBox(height: McSpacing.sm),
            McTextField(controller: descCtrl, hint: 'Descripción (opcional)'),
            const SizedBox(height: McSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                McButton(
                  label: 'Cancelar',
                  variant: McButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: McSpacing.sm),
                McButton(
                  label: 'Guardar',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    try {
      final port = context.read<BrandPort>();
      if (editing == null) {
        await port.createBrand(
          name: name,
          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
        );
      } else {
        await port.updateBrand(
          brandId: editing.id,
          name: name,
          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
          status: editing.status,
        );
      }
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('No pudimos guardar la marca. Intentá de nuevo.'), backgroundColor: McColors.error),
        );
      }
    }
  }

  Future<void> _confirmDelete(Brand brand) async {
    final confirmed = await showPosConfirm(
      context: context,
      title: 'Eliminar marca',
      message: '¿Eliminar "${brand.name}"?',
      confirmLabel: 'Eliminar',
      confirmColor: McColors.error,
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<BrandPort>().deleteBrand(brand.id);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('No pudimos eliminar la marca. Intentá de nuevo.'), backgroundColor: McColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcas'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: McColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(McSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: McColors.error),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: McSpacing.md),
            McButton(label: 'Reintentar', onPressed: _refresh),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ─── Buscador ───
        Padding(
          padding: const EdgeInsets.fromLTRB(McSpacing.md, McSpacing.md, McSpacing.md, 0),
          child: McTextField(
            controller: _searchCtrl,
            hint: 'Buscar marca...',
            prefixIcon: Icons.search,
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),

        // ─── Contador ───
        Padding(
          padding: const EdgeInsets.fromLTRB(McSpacing.md, McSpacing.sm, McSpacing.md, McSpacing.sm),
          child: Row(
            children: [
              Text(
                _brands.isEmpty
                    ? 'Sin marcas'
                    : _query.isNotEmpty
                        ? '${_filtered.length} resultado${_filtered.length == 1 ? '' : 's'}'
                        : '${_brands.length} de $_totalCount marca${_totalCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: McColors.textSecondaryLight,
                    ),
              ),
            ],
          ),
        ),

        // ─── Grid ───
        Expanded(
          child: _brands.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.branding_watermark_outlined, size: 64, color: McColors.textSecondaryLight),
                      const SizedBox(height: McSpacing.md),
                      Text('Sin marcas', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: McSpacing.sm),
                      McButton(label: 'Crear primera marca', onPressed: () => _showForm()),
                    ],
                  ),
                )
              : _filtered.isEmpty
                  ? const Center(
                      child: Text('Sin resultados', style: TextStyle(color: McColors.textSecondaryLight)),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: CustomScrollView(
                        controller: _scrollCtrl,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(McSpacing.md),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _BrandCard(
                                  brand: _filtered[i],
                                  onEdit: () => _showForm(editing: _filtered[i]),
                                  onDelete: () => _confirmDelete(_filtered[i]),
                                ),
                                childCount: _filtered.length,
                              ),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                mainAxisExtent: 120,
                                crossAxisSpacing: McSpacing.sm,
                                mainAxisSpacing: McSpacing.sm,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),

        // ─── Paginado siempre visible ───
        if (_query.isEmpty && _hasMore || (_query.isEmpty && _totalCount > _pageSize))
          _BrandPaginationBar(
            isLoadingMore: _isLoadingMore,
            hasMore: _hasMore,
            currentPage: _currentPage,
            totalCount: _totalCount,
            pageSize: _pageSize,
            onLoadMore: _loadMore,
          ),
      ],
    );
  }
}

// ─── Barra de paginado ───

class _BrandPaginationBar extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final VoidCallback onLoadMore;

  const _BrandPaginationBar({
    required this.isLoadingMore,
    required this.hasMore,
    required this.currentPage,
    required this.totalCount,
    required this.pageSize,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: McSpacing.md,
        vertical: McSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página $currentPage · $totalCount total',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: McColors.textSecondaryLight,
                ),
          ),
          if (isLoadingMore)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (hasMore)
            FilledButton.tonal(
              onPressed: onLoadMore,
              child: const Text('Cargar más'),
            )
          else
            Text(
              'Todo cargado',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: McColors.textSecondaryLight,
                  ),
            ),
        ],
      ),
    );
  }
}

// ─── Card de marca ───

class _BrandCard extends StatelessWidget {
  final Brand brand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BrandCard({
    required this.brand,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: brand.isActive ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(McSpacing.radiusMd),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(McSpacing.sm, McSpacing.sm, McSpacing.sm, 0),
                child: Center(
                  child: BrandBadge(
                    brandName: brand.name,
                    size: BrandBadgeSize.lg,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            if (brand.description != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: McSpacing.sm),
                child: Text(
                  brand.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: McColors.textSecondaryLight,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: McColors.error),
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
