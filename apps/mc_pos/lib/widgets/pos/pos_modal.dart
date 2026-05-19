import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';

/// Muestra un bottom sheet con el estilo del POS:
/// fondo claro [McColors.backgroundLight] + franja cobalt superior.
Future<T?> showPosModal<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = false,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (_) => _PosModalShell(
      child: child,
      isScrollControlled: isScrollControlled,
    ),
  );
}

/// Muestra un dialog con el estilo del POS:
/// fondo claro + borde cobalt + esquinas redondeadas.
Future<T?> showPosDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showDialog<T>(
    context: context,
    builder: (_) => Theme(
      data: McTheme.light,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              color: McColors.backgroundLight,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: McColors.primary, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33050C40),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Diálogo de confirmación estilizado — devuelve [true] si el usuario confirma.
Future<bool> showPosConfirm({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  Color? confirmColor,
  String cancelLabel = 'Cancelar',
}) async {
  final result = await showPosDialog<bool>(
    context: context,
    child: Padding(
      padding: const EdgeInsets.all(McSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: McColors.foregroundLight,
            ),
          ),
          const SizedBox(height: McSpacing.sm),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: McColors.textFg2,
            ),
          ),
          const SizedBox(height: McSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelLabel),
              ),
              const SizedBox(width: McSpacing.sm),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: confirmColor ?? McColors.primary,
                ),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

// ─── Shell del bottom sheet ───

class _PosModalShell extends StatelessWidget {
  final Widget child;
  final bool isScrollControlled;

  const _PosModalShell({
    required this.child,
    this.isScrollControlled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: McTheme.light,
      child: Container(
        decoration: BoxDecoration(
          color: McColors.backgroundLight,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: McColors.primary, width: 3),
            left: BorderSide(color: McColors.primary.withValues(alpha: 0.4), width: 1),
            right: BorderSide(color: McColors.primary.withValues(alpha: 0.4), width: 1),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: isScrollControlled
                ? MainAxisSize.max
                : MainAxisSize.min,
            children: [
              // Handle pill cobalt
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: McColors.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(McSpacing.radiusFull),
                  ),
                ),
              ),
              if (isScrollControlled)
                Expanded(child: child)
              else
                child,
            ],
          ),
        ),
      ),
    );
  }
}
