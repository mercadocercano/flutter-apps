import 'package:flutter/material.dart';
import '../theme/mc_spacing.dart';

/// Campo de texto de Mercado Cercano.
class McTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool autofocus;
  final IconData? prefixIcon;
  final Widget? suffix;

  const McTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.autofocus = false,
    this.prefixIcon,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: McSpacing.base,
          vertical: McSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(McSpacing.radiusMd),
        ),
      ),
    );
  }
}
