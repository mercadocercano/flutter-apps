import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_design_system/mc_design_system.dart';
import '../../constants/pos_constants.dart';

/// Indicador de estado de sincronización del POS.
class SyncPill extends StatelessWidget {
  final PosSyncStatus status;

  const SyncPill({super.key, required this.status});

  Color get _dotColor => switch (status) {
        PosSyncStatus.synced => McColors.success,
        PosSyncStatus.syncing => McColors.warning,
        PosSyncStatus.offline => McColors.textFg2,
      };

  String get _label => switch (status) {
        PosSyncStatus.synced => 'Sincronizado',
        PosSyncStatus.syncing => 'Sincronizando',
        PosSyncStatus.offline => 'Sin red',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: McSpacing.sm,
        vertical: McSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: McColors.mutedLight,
        borderRadius: BorderRadius.circular(McSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: McSpacing.xs),
          Text(
            _label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: McColors.textFg2,
            ),
          ),
        ],
      ),
    );
  }
}
