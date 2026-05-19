import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'product_card_pos.dart' show fmtAR;

/// Fila de denominación para el arqueo de caja.
class DenominationRow extends StatelessWidget {
  final int denomination;
  final int qty;
  final ValueChanged<int> onQtyChanged;

  const DenominationRow({
    super.key,
    required this.denomination,
    required this.qty,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: McSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fmtAR(denomination.toDouble()),
              style: McTypography.mono(13, color: McColors.foregroundLight),
            ),
          ),
          Text(
            '×',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: McColors.textFg2,
            ),
          ),
          const SizedBox(width: McSpacing.sm),
          // Stepper pill
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: McColors.mutedLight,
              borderRadius: BorderRadius.circular(McSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepBtn(
                  label: '−',
                  onTap: () {
                    if (qty > 0) onQtyChanged(qty - 1);
                  },
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$qty',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: McColors.foregroundLight,
                    ),
                  ),
                ),
                _StepBtn(
                  label: '+',
                  onTap: () => onQtyChanged(qty + 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: McSpacing.sm),
          Expanded(
            child: Text(
              fmtAR((denomination * qty).toDouble()),
              textAlign: TextAlign.right,
              style: McTypography.mono(13, color: McColors.textFg2),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: McColors.textFg2,
          ),
        ),
      ),
    );
  }
}
