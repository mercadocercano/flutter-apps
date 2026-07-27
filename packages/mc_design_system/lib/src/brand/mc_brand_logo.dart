import 'package:flutter/material.dart';

/// Logo de marca de Mercado Cercano (storefront + "MC" + cursor).
///
/// El asset `pin_mc.png` es opaco (fondo blanco), por eso sobre fondos oscuros
/// conviene [badge] = true, que lo encierra en un círculo blanco recortado
/// (sin esquinas cuadradas). Sobre superficies blancas (una Card), [badge]
/// = false alcanza: el fondo blanco del PNG se funde solo.
class McBrandLogo extends StatelessWidget {
  /// Lado del logo en px lógicos.
  final double size;

  /// Si true, envuelve el logo en un badge blanco circular con sombra
  /// (para fondos oscuros / sobre el scrim del login).
  final bool badge;

  const McBrandLogo({super.key, this.size = 72, this.badge = false});

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      'assets/brand/pin_mc.png',
      package: 'mc_design_system',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    if (!badge) return img;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: img,
    );
  }
}
