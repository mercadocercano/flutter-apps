import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';

/// Dialog de confirmación para rechazar la imagen activa de un producto.
///
/// Retorna `true` al confirmar, `false`/null al cancelar.
class RejectImageDialog extends StatelessWidget {
  const RejectImageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: McColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: McColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Rechazar imagen'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Rechazar esta imagen?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Se buscará una nueva en el próximo enriquecimiento.',
            style: TextStyle(
              fontSize: 13,
              color: McColors.textFg2,
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
          label: 'Rechazar',
          size: McButtonSize.sm,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
