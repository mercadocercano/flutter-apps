import 'package:flutter/material.dart';

import 'stat_item.dart';

/// Tarjeta de sección del dashboard que agrupa un conjunto de métricas.
///
/// Muestra un encabezado con [title] e [icon] usando [color] como acento, y
/// debajo una grilla de 2 columnas con los [items]. Soporta estados de
/// carga y error.
class StatsSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<StatItem> items;
  final bool isLoading;
  final bool hasError;

  const StatsSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    this.isLoading = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: title, icon: icon, color: color),
          _CardBody(
            items: items,
            color: color,
            isLoading: isLoading,
            hasError: hasError,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Encabezado
// ---------------------------------------------------------------------------

class _CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _CardHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cuerpo: carga / error / datos
// ---------------------------------------------------------------------------

class _CardBody extends StatelessWidget {
  final List<StatItem> items;
  final Color color;
  final bool isLoading;
  final bool hasError;

  const _CardBody({
    required this.items,
    required this.color,
    required this.isLoading,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    if (hasError) return const _ErrorBody();
    if (isLoading) return const _LoadingBody();
    return _DataGrid(items: items, color: color);
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            'Datos no disponibles',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: List.generate(4, (_) => const _SkeletonCell()),
      ),
    );
  }
}

class _SkeletonCell extends StatelessWidget {
  const _SkeletonCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _DataGrid extends StatelessWidget {
  final List<StatItem> items;
  final Color color;

  const _DataGrid({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: items
            .map((item) => _StatCell(item: item, color: color))
            .toList(),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final StatItem item;
  final Color color;

  const _StatCell({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${item.value}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          item.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        if (item.subtitle != null)
          Text(
            item.subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
