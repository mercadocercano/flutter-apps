import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import '../../../widgets/pos/pos_modal.dart';

/// Selector de cliente — búsqueda + creación rápida.
/// Por defecto usa "Consumidor Final".
class CustomerSelector extends StatefulWidget {
  final Customer? selected;
  final ValueChanged<Customer> onSelected;

  const CustomerSelector({
    super.key,
    this.selected,
    required this.onSelected,
  });

  @override
  State<CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends State<CustomerSelector> {
  @override
  Widget build(BuildContext context) {
    final customer = widget.selected;
    final isDefault = customer == null || customer.isDefault;

    return InkWell(
      onTap: () => _showCustomerSheet(context),
      borderRadius: BorderRadius.circular(McSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: McSpacing.md,
          vertical: McSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(McSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              isDefault ? Icons.person_outline : Icons.person,
              size: 20,
              color: isDefault ? McColors.textSecondaryLight : McColors.primary,
            ),
            const SizedBox(width: McSpacing.sm),
            Expanded(
              child: Text(
                customer?.displayName ?? 'Consumidor Final',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDefault ? McColors.textSecondaryLight : null,
                    ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCustomerSheet(BuildContext context) {
    showPosModal(
      context: context,
      isScrollControlled: true,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => _CustomerSearchSheet(
          scrollController: scrollController,
          onSelected: (c) {
            widget.onSelected(c);
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }
}

class _CustomerSearchSheet extends StatefulWidget {
  final ScrollController scrollController;
  final ValueChanged<Customer> onSelected;

  const _CustomerSearchSheet({
    required this.scrollController,
    required this.onSelected,
  });

  @override
  State<_CustomerSearchSheet> createState() => _CustomerSearchSheetState();
}

class _CustomerSearchSheetState extends State<_CustomerSearchSheet> {
  final _searchController = TextEditingController();
  List<Customer> _results = _demoCustomers;
  bool _showCreateForm = false;

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = _demoCustomers;
      } else {
        _results = _demoCustomers
            .where((c) =>
                c.name.toLowerCase().contains(query.toLowerCase()) ||
                (c.phone?.contains(query) ?? false) ||
                (c.document?.contains(query) ?? false))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: McSpacing.sm),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(McSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: McTextField(
                  hint: 'Buscar por nombre, teléfono o DNI...',
                  controller: _searchController,
                  onChanged: _search,
                  prefixIcon: Icons.search,
                  autofocus: true,
                ),
              ),
              const SizedBox(width: McSpacing.sm),
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () => setState(() => _showCreateForm = true),
                tooltip: 'Nuevo cliente',
              ),
            ],
          ),
        ),
        if (_showCreateForm) ...[
          _QuickCreateForm(
            onCreated: (customer) {
              widget.onSelected(customer);
              setState(() => _showCreateForm = false);
            },
            onCancel: () => setState(() => _showCreateForm = false),
          ),
        ] else
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final c = _results[i];
                return ListTile(
                  leading: Icon(
                    c.isDefault ? Icons.storefront : Icons.person,
                    color: c.isDefault ? McColors.secondary : McColors.primary,
                  ),
                  title: Text(c.name),
                  subtitle: c.phone != null ? Text(c.phone!) : null,
                  trailing: c.document != null
                      ? Text(c.document!,
                          style: Theme.of(context).textTheme.bodySmall)
                      : null,
                  onTap: () => widget.onSelected(c),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Formulario de creación rápida inline.
class _QuickCreateForm extends StatefulWidget {
  final ValueChanged<Customer> onCreated;
  final VoidCallback onCancel;

  const _QuickCreateForm({required this.onCreated, required this.onCancel});

  @override
  State<_QuickCreateForm> createState() => _QuickCreateFormState();
}

class _QuickCreateFormState extends State<_QuickCreateForm> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _create() {
    if (_nameCtrl.text.trim().isEmpty) return;
    // TODO: conectar con CustomerPort real
    final customer = Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tenantId: 'demo',
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );
    widget.onCreated(customer);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: McSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nuevo cliente',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: McSpacing.sm),
          McTextField(
            label: 'Nombre',
            controller: _nameCtrl,
            autofocus: true,
          ),
          const SizedBox(height: McSpacing.sm),
          McTextField(
            label: 'Teléfono (opcional)',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: McSpacing.md),
          Row(
            children: [
              McButton(
                label: 'Cancelar',
                variant: McButtonVariant.ghost,
                size: McButtonSize.sm,
                onPressed: widget.onCancel,
              ),
              const SizedBox(width: McSpacing.sm),
              McButton(
                label: 'Agregar',
                size: McButtonSize.sm,
                onPressed: _create,
              ),
            ],
          ),
          const SizedBox(height: McSpacing.md),
        ],
      ),
    );
  }
}

/// Clientes demo — se reemplazarán con CustomerPort.
final _demoCustomers = [
  const Customer(
      id: 'default', tenantId: 'demo', name: 'Consumidor Final'),
  const Customer(
      id: '1', tenantId: 'demo', name: 'María González', phone: '3764-551234'),
  const Customer(
      id: '2',
      tenantId: 'demo',
      name: 'Carlos Rodríguez',
      phone: '3764-449876',
      document: '28.456.789'),
  const Customer(
      id: '3', tenantId: 'demo', name: 'Ana Fernández', phone: '3764-332211'),
  const Customer(
      id: '4',
      tenantId: 'demo',
      name: 'Pedro Martínez',
      document: '35.123.456'),
];
