import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_design_system/mc_design_system.dart';

/// Barra de búsqueda del POS con botón de escaneo.
class PosSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onScan;
  final ValueChanged<String>? onChanged;

  const PosSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    this.onScan,
    this.onChanged,
  });

  @override
  State<PosSearchBar> createState() => _PosSearchBarState();
}

class _PosSearchBarState extends State<PosSearchBar> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        McSpacing.md,
        McSpacing.base,
        McSpacing.md,
        McSpacing.sm,
      ),
      color: Colors.white,
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : McColors.mutedLight,
            borderRadius: BorderRadius.circular(McSpacing.radiusMd),
            border: _isFocused
                ? Border.all(color: McColors.primary, width: 2)
                : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: McSpacing.md),
              Icon(
                Icons.search,
                size: 20,
                color: McColors.textFg2,
              ),
              const SizedBox(width: McSpacing.sm),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  onChanged: widget.onChanged,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: McColors.foregroundLight,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: McColors.textFg2,
                    ),
                  ),
                ),
              ),
              if (widget.controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    widget.controller.clear();
                    widget.onChanged?.call('');
                    setState(() {});
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: McSpacing.sm),
                    child: Icon(Icons.close, size: 18, color: McColors.textFg2),
                  ),
                ),
              GestureDetector(
                onTap: widget.onScan,
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: McColors.primary,
                    borderRadius: BorderRadius.circular(McSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
