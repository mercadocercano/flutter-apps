import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_snackbars.dart';
import 'blocs/attribute_form_bloc.dart';
import 'blocs/attribute_values_bloc.dart';

class AttributeDetailScreen extends StatefulWidget {
  final String attributeId;

  const AttributeDetailScreen({super.key, required this.attributeId});

  @override
  State<AttributeDetailScreen> createState() => _AttributeDetailScreenState();
}

class _AttributeDetailScreenState extends State<AttributeDetailScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<AttributeFormBloc>()
        .add(LoadAttributeEvent(widget.attributeId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttributeFormBloc, AttributeFormState>(
      listener: _onStateChange,
      child: BlocBuilder<AttributeFormBloc, AttributeFormState>(
        builder: (context, state) {
          if (state is AttributeFormLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is AttributeFormError) {
            return _ErrorScaffold(
              message: state.message,
              onRetry: () => context
                  .read<AttributeFormBloc>()
                  .add(LoadAttributeEvent(widget.attributeId)),
            );
          }

          if (state is AttributeFormLoaded) {
            return _DetailView(attribute: state.attribute);
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  void _onStateChange(BuildContext context, AttributeFormState state) {
    if (state is AttributeFormError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}

// --- Error scaffold ---

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de atributo')),
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

// --- Vista principal de detalle ---

class _DetailView extends StatelessWidget {
  final MarketplaceAttribute attribute;

  const _DetailView({required this.attribute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(attribute.name),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar'),
            onPressed: () =>
                context.push('/pim/attributes/${attribute.id}/edit'),
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
                _InfoCard(
                  title: 'Información general',
                  children: [
                    _InfoRow('ID', attribute.id),
                    _InfoRow('Nombre', attribute.name),
                    _InfoRow('Slug', attribute.slug),
                    _InfoRowWithWidget(
                      label: 'Tipo',
                      child: _TypeChip(type: attribute.type),
                    ),
                    if (attribute.description != null)
                      _InfoRow('Descripción', attribute.description!),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Configuración',
                  children: [
                    _InfoRowWithWidget(
                      label: 'Obligatorio',
                      child: _BoolBadge(value: attribute.isRequired),
                    ),
                    _InfoRowWithWidget(
                      label: 'Filtrable',
                      child: _BoolBadge(value: attribute.isFilterable),
                    ),
                  ],
                ),
                if (attribute.type.hasValues) ...[
                  const SizedBox(height: 16),
                  _ValuesCard(attributeId: attribute.id),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Card de valores (read-only con BLoC) ---

class _ValuesCard extends StatelessWidget {
  final String attributeId;

  const _ValuesCard({required this.attributeId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttributeValuesBloc, AttributeValuesState>(
      builder: (context, state) {
        final values =
            state is AttributeValuesLoaded ? state.values : <AttributeValue>[];
        final isLoading = state is AttributeValuesLoading;
        final error =
            state is AttributeValuesError ? state.message : null;

        return _InfoCard(
          title: 'Valores (${values.length})',
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (error != null)
              Text(error, style: TextStyle(color: Colors.red[700]))
            else if (values.isEmpty)
              const Text(
                'Sin valores. Edita el atributo para agregar valores.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...values.map((v) => _ValueRow(value: v)),
          ],
        );
      },
    );
  }
}

class _ValueRow extends StatelessWidget {
  final AttributeValue value;

  const _ValueRow({required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              value.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.value,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            '#${value.sortOrder}',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// --- Widgets reutilizables ---

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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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

class _TypeChip extends StatelessWidget {
  final AttributeType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(type);
    return Chip(
      label: Text(
        type.displayLabel,
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: color.withAlpha(26),
      side: BorderSide(color: color.withAlpha(77)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _colorForType(AttributeType type) => switch (type) {
        AttributeType.text => Colors.blue,
        AttributeType.number => Colors.purple,
        AttributeType.boolean => Colors.orange,
        AttributeType.select => Colors.green,
        AttributeType.multiSelect => Colors.teal,
      };
}

class _BoolBadge extends StatelessWidget {
  final bool value;

  const _BoolBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        value ? 'Sí' : 'No',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: (value ? Colors.green : Colors.grey).withAlpha(26),
      side: BorderSide(
        color: (value ? Colors.green : Colors.grey).withAlpha(77),
      ),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// --- Extensión de display labels ---

extension _AttributeTypeLabel on AttributeType {
  String get displayLabel => switch (this) {
        AttributeType.text => 'Texto',
        AttributeType.number => 'Número',
        AttributeType.boolean => 'Booleano',
        AttributeType.select => 'Selección',
        AttributeType.multiSelect => 'Multi-selección',
      };
}
