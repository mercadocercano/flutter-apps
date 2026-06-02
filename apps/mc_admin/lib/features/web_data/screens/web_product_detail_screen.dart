import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/status_badge.dart';
import '../blocs/web_products_bloc.dart';

class WebProductDetailScreen extends StatefulWidget {
  final String productId;

  const WebProductDetailScreen({super.key, required this.productId});

  @override
  State<WebProductDetailScreen> createState() => _WebProductDetailScreenState();
}

class _WebProductDetailScreenState extends State<WebProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  WebProduct? _product;
  List<PricePoint> _priceHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProduct();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final productUseCase = context.read<GetWebProductUseCase>();
      final historyUseCase = context.read<GetPriceHistoryUseCase>();

      final results = await Future.wait([
        productUseCase.execute(widget.productId),
        historyUseCase.execute(widget.productId),
      ]);

      if (mounted) {
        setState(() {
          _product = results[0] as WebProduct;
          _priceHistory = results[1] as List<PricePoint>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al cargar producto: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.name ?? 'Detalle de Producto'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Información'),
            Tab(text: 'Historial de Precios'),
          ],
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProduct,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_product == null) return const SizedBox.shrink();

    return TabBarView(
      controller: _tabController,
      children: [
        _InfoTab(product: _product!, onAssign: _onAssignBusinessType),
        _PriceHistoryTab(priceHistory: _priceHistory),
      ],
    );
  }

  Future<void> _onAssignBusinessType() async {
    final businessTypeId = await showDialog<String>(
      context: context,
      builder: (_) => const _BusinessTypeDialog(),
    );
    if (businessTypeId != null && mounted) {
      context.read<WebProductsBloc>().add(
            AssignBusinessTypeEvent(
              id: _product!.id,
              businessTypeId: businessTypeId,
            ),
          );
      AdminSnackbars.showSuccess(context, 'Tipo de comercio asignado.');
      _loadProduct();
    }
  }
}

// ---------------------------------------------------------------------------
// Tab de información general
// ---------------------------------------------------------------------------

class _InfoTab extends StatelessWidget {
  final WebProduct product;
  final VoidCallback onAssign;

  const _InfoTab({required this.product, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.imageUrl != null) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl!,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(label: 'Nombre', value: product.name),
                  _DetailRow(
                    label: 'Precio',
                    value: '\$${product.price.toStringAsFixed(2)}',
                  ),
                  _DetailRow(label: 'Fuente', value: product.sourceId),
                  _DetailRow(
                    label: 'Tipo de comercio',
                    widget: product.hasBusinessType
                        ? StatusBadge.fromString('active',
                            customLabel: product.businessTypeId!)
                        : const StatusBadge(
                            status: AdminStatus.pending,
                            customLabel: 'Sin asignar',
                          ),
                  ),
                  _DetailRow(
                    label: 'Scrapeado',
                    value: _formatDateTime(product.scrapedAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.label_outline, size: 16),
            label: const Text('Asignar tipo de comercio'),
            onPressed: onAssign,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? widget;

  const _DetailRow({required this.label, this.value, this.widget})
      : assert(value != null || widget != null);

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
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: widget ??
                Text(
                  value!,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab de historial de precios
// ---------------------------------------------------------------------------

class _PriceHistoryTab extends StatelessWidget {
  final List<PricePoint> priceHistory;

  const _PriceHistoryTab({required this.priceHistory});

  @override
  Widget build(BuildContext context) {
    if (priceHistory.isEmpty) {
      return const Center(
        child: Text('Sin historial de precios disponible.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de Precios',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _PriceHistoryTable(points: priceHistory),
        ],
      ),
    );
  }
}

class _PriceHistoryTable extends StatelessWidget {
  final List<PricePoint> points;

  const _PriceHistoryTable({required this.points});

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Fecha')),
        DataColumn(label: Text('Precio'), numeric: true),
        DataColumn(label: Text('Variación'), numeric: true),
      ],
      rows: points.map((p) => _buildRow(context, p)).toList(),
    );
  }

  DataRow _buildRow(BuildContext context, PricePoint point) {
    final variationText = point.variationPercent == null
        ? '—'
        : '${point.variationPercent! >= 0 ? '+' : ''}${point.variationPercent!.toStringAsFixed(1)}%';

    final variationColor = point.isPriceIncrease
        ? Colors.red[700]
        : point.isPriceDecrease
            ? Colors.green[700]
            : null;

    return DataRow(cells: [
      DataCell(Text(_formatDate(point.date))),
      DataCell(Text('\$${point.price.toStringAsFixed(2)}')),
      DataCell(
        Text(
          variationText,
          style: TextStyle(
            color: variationColor,
            fontWeight: point.variationPercent != null
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ),
    ]);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// Diálogo selector de business type
// ---------------------------------------------------------------------------

class _BusinessTypeDialog extends StatefulWidget {
  const _BusinessTypeDialog();

  @override
  State<_BusinessTypeDialog> createState() => _BusinessTypeDialogState();
}

class _BusinessTypeDialogState extends State<_BusinessTypeDialog> {
  String? _selectedId;

  static const _options = [
    ('ferreteria', 'Ferretería'),
    ('supermercado', 'Supermercado'),
    ('panaderia', 'Panadería'),
    ('farmacia', 'Farmacia'),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar tipo de comercio'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _options
              .map(
                (option) => RadioListTile<String>(
                  title: Text(option.$2),
                  value: option.$1,
                  groupValue: _selectedId,
                  onChanged: (v) => setState(() => _selectedId = v),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed:
              _selectedId != null ? () => Navigator.of(context).pop(_selectedId) : null,
          child: const Text('Asignar'),
        ),
      ],
    );
  }
}
