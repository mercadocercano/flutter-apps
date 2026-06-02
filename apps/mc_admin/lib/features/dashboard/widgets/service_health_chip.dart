import 'package:flutter/material.dart';

/// Estado de salud posible para un servicio del marketplace.
enum ServiceStatus { online, degraded, offline }

/// Chip que muestra el estado de salud de un microservicio.
///
/// Incluye un punto de color (verde/naranja/rojo), el nombre del servicio y,
/// opcionalmente, la latencia en ms. Al hacer hover muestra un [Tooltip] con
/// la información completa.
class ServiceHealthChip extends StatelessWidget {
  final String serviceName;
  final String status;
  final int? latencyMs;

  const ServiceHealthChip({
    super.key,
    required this.serviceName,
    required this.status,
    this.latencyMs,
  });

  ServiceStatus get _parsedStatus => switch (status) {
        'online' => ServiceStatus.online,
        'degraded' => ServiceStatus.degraded,
        'offline' => ServiceStatus.offline,
        _ => ServiceStatus.offline,
      };

  Color _dotColor(ServiceStatus s) => switch (s) {
        ServiceStatus.online => const Color(0xFF22C55E),
        ServiceStatus.degraded => const Color(0xFFF97316),
        ServiceStatus.offline => const Color(0xFFEF4444),
      };

  String _statusLabel(ServiceStatus s) => switch (s) {
        ServiceStatus.online => 'online',
        ServiceStatus.degraded => 'degraded',
        ServiceStatus.offline => 'offline',
      };

  String _tooltipText(ServiceStatus s) {
    final base = '$serviceName: ${_statusLabel(s)}';
    if (latencyMs != null) return '$base — ${latencyMs}ms';
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsedStatus;
    final dotColor = _dotColor(parsed);

    return Tooltip(
      message: _tooltipText(parsed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: dotColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dotColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusDot(color: dotColor),
            const SizedBox(width: 6),
            Text(
              serviceName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (latencyMs != null) ...[
              const SizedBox(width: 4),
              Text(
                '(${latencyMs}ms)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
