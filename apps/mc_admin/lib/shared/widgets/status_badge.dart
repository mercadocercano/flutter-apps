import 'package:flutter/material.dart';

enum AdminStatus { active, inactive, pending, verified, unverified, running, failed, completed, cancelled }

/// Badge coloreado para representar estados en tablas y detalles.
class StatusBadge extends StatelessWidget {
  final AdminStatus status;
  final String? customLabel;

  const StatusBadge({super.key, required this.status, this.customLabel});

  /// Construye un StatusBadge desde un string (para mapeo desde API).
  factory StatusBadge.fromString(String value, {String? customLabel}) {
    final s = value.toLowerCase();
    final mapped = switch (s) {
      'active' || 'activo' || 'activated' => AdminStatus.active,
      'inactive' || 'inactivo' || 'deactivated' => AdminStatus.inactive,
      'pending' || 'pendiente' => AdminStatus.pending,
      'verified' || 'verificado' => AdminStatus.verified,
      'unverified' || 'no verificado' => AdminStatus.unverified,
      'running' || 'corriendo' || 'in_progress' => AdminStatus.running,
      'failed' || 'fallido' || 'error' => AdminStatus.failed,
      'completed' || 'completado' || 'done' => AdminStatus.completed,
      'cancelled' || 'cancelado' => AdminStatus.cancelled,
      _ => AdminStatus.pending,
    };
    return StatusBadge(status: mapped, customLabel: customLabel ?? value);
  }

  String get _label {
    if (customLabel != null) return customLabel!;
    return switch (status) {
      AdminStatus.active => 'Activo',
      AdminStatus.inactive => 'Inactivo',
      AdminStatus.pending => 'Pendiente',
      AdminStatus.verified => 'Verificado',
      AdminStatus.unverified => 'No verificado',
      AdminStatus.running => 'Corriendo',
      AdminStatus.failed => 'Fallido',
      AdminStatus.completed => 'Completado',
      AdminStatus.cancelled => 'Cancelado',
    };
  }

  Color _bgColor(ColorScheme c) => switch (status) {
        AdminStatus.active || AdminStatus.verified || AdminStatus.completed =>
          c.primaryContainer,
        AdminStatus.inactive || AdminStatus.cancelled => c.surfaceContainerHighest,
        AdminStatus.pending || AdminStatus.unverified => c.tertiaryContainer,
        AdminStatus.running => c.secondaryContainer,
        AdminStatus.failed => c.errorContainer,
      };

  Color _textColor(ColorScheme c) => switch (status) {
        AdminStatus.active || AdminStatus.verified || AdminStatus.completed =>
          c.onPrimaryContainer,
        AdminStatus.inactive || AdminStatus.cancelled => c.onSurfaceVariant,
        AdminStatus.pending || AdminStatus.unverified => c.onTertiaryContainer,
        AdminStatus.running => c.onSecondaryContainer,
        AdminStatus.failed => c.onErrorContainer,
      };

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor(c),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _textColor(c),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
