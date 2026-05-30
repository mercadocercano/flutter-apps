import 'package:flutter/material.dart';

/// Chip de filtro individual.
class AdminFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final void Function(bool selected) onSelected;
  final VoidCallback? onDelete;

  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: selected,
      onSelected: onSelected,
      deleteIcon: onDelete != null ? const Icon(Icons.close, size: 14) : null,
      onDeleted: onDelete,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Fila de chips de filtro.
class AdminFilterChips extends StatelessWidget {
  final List<AdminFilterChipData> chips;

  const AdminFilterChips({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: chips
            .map(
              (chip) => AdminFilterChip(
                label: chip.label,
                selected: chip.selected,
                onSelected: chip.onSelected,
                onDelete: chip.onDelete,
              ),
            )
            .toList(),
      ),
    );
  }
}

class AdminFilterChipData {
  final String label;
  final bool selected;
  final void Function(bool selected) onSelected;
  final VoidCallback? onDelete;

  const AdminFilterChipData({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.onDelete,
  });
}
