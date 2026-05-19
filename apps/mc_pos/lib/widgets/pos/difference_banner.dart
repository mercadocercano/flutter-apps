import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'product_card_pos.dart' show fmtAR;

/// Banner de diferencia para el arqueo de caja.
/// Muestra contado vs sistema y la diferencia con código de color.
class DifferenceBanner extends StatelessWidget {
  final double system;
  final double counted;

  const DifferenceBanner({
    super.key,
    required this.system,
    required this.counted,
  });

  @override
  Widget build(BuildContext context) {
    final diff = counted - system;

    final Color bg;
    final Color fg;
    final Color border;

    if (diff == 0) {
      bg = McColors.successTint;
      fg = McColors.success;
      border = McColors.success;
    } else if (diff > 0) {
      bg = McColors.warningTint;
      fg = McColors.warning;
      border = McColors.warning;
    } else {
      bg = McColors.errorTint;
      fg = McColors.error;
      border = McColors.error;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AmountRow(
            label: 'Contado',
            value: fmtAR(counted),
            labelColor: McColors.textFg2,
            valueColor: McColors.foregroundLight,
          ),
          const SizedBox(height: McSpacing.xs),
          _AmountRow(
            label: 'Sistema',
            value: fmtAR(system),
            labelColor: McColors.textFg2,
            valueColor: McColors.foregroundLight,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: McSpacing.sm),
            child: Divider(height: 1, color: McColors.borderLight),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diferencia',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              Text(
                '${diff >= 0 ? '+' : ''}${fmtAR(diff.abs())}',
                style: McTypography.mono(18, color: fg),
              ),
            ],
          ),
          if (diff != 0) ...[
            const SizedBox(height: 6),
            Text(
              diff < 0
                  ? 'Falta plata, revisá vueltos pendientes'
                  : 'Sobra plata, puede ser apertura mal cargada',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: McColors.textFg2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _AmountRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: labelColor,
          ),
        ),
        Text(
          value,
          style: McTypography.mono(15, color: valueColor),
        ),
      ],
    );
  }
}
