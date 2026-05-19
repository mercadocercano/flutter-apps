import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_design_system/mc_design_system.dart';

/// Card de KPI para el dashboard y pantalla de stock.
class KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? toneColor;

  const KpiCard({
    super.key,
    required this.value,
    required this.label,
    this.toneColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = toneColor;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: McSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color != null
              ? color.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
            color: color ?? McColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(McSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: McTypography.mono(
                22,
                weight: FontWeight.w700,
                color: color ?? McColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: McColors.textFg2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
