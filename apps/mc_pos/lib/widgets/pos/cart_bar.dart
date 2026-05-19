import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'product_card_pos.dart' show fmtAR;

/// Barra inferior del carrito para mobile.
/// Retorna [SizedBox.shrink()] cuando [count] == 0.
class CartBar extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onTap;

  const CartBar({
    super.key,
    required this.count,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: McColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: McSpacing.base,
          vertical: 14,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Pill de cantidad
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ver carrito',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    '$count producto${count == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                fmtAR(total),
                style: McTypography.mono(19, color: Colors.white),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
