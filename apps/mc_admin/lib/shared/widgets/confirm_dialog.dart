import 'package:flutter/material.dart';

/// Diálogo de confirmación para operaciones destructivas.
///
/// Uso:
/// ```dart
/// final confirmed = await ConfirmDialog.show(
///   context,
///   title: '¿Eliminar tenant?',
///   message: 'Esta acción no se puede deshacer.',
///   confirmLabel: 'Eliminar',
///   isDangerous: true,
/// );
/// if (confirmed == true) { ... }
/// ```
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDangerous;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.isDangerous = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDangerous: isDangerous,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDangerous
              ? FilledButton.styleFrom(backgroundColor: c.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
