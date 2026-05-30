import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_data_table.dart';
import '../../../shared/widgets/status_badge.dart';
import 'plans_bloc.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlansBloc, PlansState>(
      builder: (context, state) {
        final plans = state is PlansLoaded ? state.plans : <Plan>[];
        final isLoading = state is PlansLoading;
        final error = state is PlansError ? state.message : null;
        final currentPage = state is PlansLoaded ? state.currentPage : 1;
        final pageSize = state is PlansLoaded ? state.pageSize : 20;
        final totalItems = state is PlansLoaded ? state.totalItems : 0;

        return AdminDataTable<Plan>(
          items: plans,
          isLoading: isLoading,
          error: error,
          onRetry: () => context.read<PlansBloc>().add(LoadPlansEvent()),
          currentPage: currentPage,
          pageSize: pageSize,
          totalItems: totalItems,
          onPageChanged: (page) =>
              context.read<PlansBloc>().add(ChangePlansPageEvent(page)),
          searchHint: 'Buscar plan...',
          onSearch: (query) => context.read<PlansBloc>().add(
                LoadPlansEvent(searchQuery: query.isEmpty ? null : query),
              ),
          createLabel: 'Nuevo Plan',
          onCreateTap: () => context.push('/iam/plans/new'),
          columns: [
            AdminColumn<Plan>(
              label: 'Nombre',
              builder: (item) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (item.description != null)
                    Text(
                      item.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            AdminColumn<Plan>(
              label: 'Tipo',
              builder: (item) => Chip(
                label: Text(
                  _planTypeLabel(item.type),
                  style: const TextStyle(fontSize: 11),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            AdminColumn<Plan>(
              label: 'Precio',
              builder: (item) => Text(
                item.price == 0
                    ? 'Gratis'
                    : '\$ ${_formatPrice(item.price)} ${item.currency}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            AdminColumn<Plan>(
              label: 'Features',
              builder: (item) => Text('${item.features.length} feature(s)'),
            ),
            AdminColumn<Plan>(
              label: 'Estado',
              builder: (item) => StatusBadge.fromString(item.status.name),
            ),
            AdminColumn<Plan>(
              label: 'Acciones',
              builder: (item) => _PlanRowActions(plan: item),
            ),
          ],
        );
      },
    );
  }

  String _planTypeLabel(PlanType type) {
    return switch (type) {
      PlanType.free => 'Free',
      PlanType.starter => 'Starter',
      PlanType.professional => 'Professional',
      PlanType.enterprise => 'Enterprise',
    };
  }

  String _formatPrice(double price) {
    final parts = price.toStringAsFixed(0).split('');
    final result = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(parts[i]);
    }
    return result.toString();
  }
}

class _PlanRowActions extends StatelessWidget {
  final Plan plan;
  const _PlanRowActions({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Editar',
          onPressed: () => context.push('/iam/plans/${plan.id}/edit'),
        ),
      ],
    );
  }
}
