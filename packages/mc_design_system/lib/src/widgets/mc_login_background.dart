import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';

/// Fondo de login "mapa del barrio" con pines de comercio animados.
///
/// Concepto de marca: el logo de Mercado Cercano son dos pines de ubicación
/// (hogar + comercio) conectados por una línea punteada. Esta pantalla lleva
/// esa metáfora al fondo del login: un mapa del barrio con pines que laten y
/// caen, y una línea punteada hogar→comercio.
///
/// **Drop-in de la imagen final**: por defecto dibuja un mapa procedural
/// (placeholder, sin assets). Cuando tengas la imagen real (IA estilo satelital
/// o un static export de Mapbox), pasala por [mapImage]:
///
/// ```dart
/// McLoginBackground(
///   mapImage: const AssetImage('assets/images/login_map.webp'),
///   child: ...,
/// )
/// ```
///
/// Los pines son una **capa Flutter** (no van horneados en la imagen) para
/// poder animarlos. La imagen del mapa debe venir LIMPIA, sin marcadores.
///
/// Respeta `MediaQuery.disableAnimations` (accesibilidad / prefers-reduced-motion):
/// con reduce-motion activo, todo queda estático.
class McLoginBackground extends StatefulWidget {
  /// Contenido por encima del fondo (típicamente la Card centrada del form).
  final Widget child;

  /// Imagen real del mapa. Si es null, se dibuja el placeholder procedural.
  final ImageProvider? mapImage;

  /// Habilita la animación de pines/línea. Se desactiva solo si el sistema
  /// pide reduce-motion.
  final bool animate;

  const McLoginBackground({
    super.key,
    required this.child,
    this.mapImage,
    this.animate = true,
  });

  @override
  State<McLoginBackground> createState() => _McLoginBackgroundState();
}

class _McLoginBackgroundState extends State<McLoginBackground>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _intro;
  bool _animate = true;

  // Pines en coordenadas normalizadas (Alignment -1..1). Se evita el centro,
  // donde vive la Card del formulario. El índice 0 es el pin "hogar" y el
  // índice 1 es el comercio de MARCA (badge con el logo): la línea punteada
  // va de 0 → 1. Ambos a la izquierda para que la línea quede visible.
  static const _pins = <_PinSpec>[
    _PinSpec(Alignment(-0.80, -0.48), home: true),
    _PinSpec(Alignment(-0.50, 0.46), brand: true),
    _PinSpec(Alignment(0.66, -0.72)),
    _PinSpec(Alignment(0.84, 0.12)),
    _PinSpec(Alignment(0.55, 0.66)),
    _PinSpec(Alignment(-0.88, 0.66)),
    _PinSpec(Alignment(0.30, -0.86)),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.mapImage != null) {
      precacheImage(widget.mapImage!, context);
    }
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _animate = widget.animate && !reduceMotion;
    if (_animate) {
      if (!_pulse.isAnimating) _pulse.repeat();
      if (_intro.status == AnimationStatus.dismissed) _intro.forward();
    } else {
      _pulse.stop();
      _intro.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Mapa: imagen real o placeholder procedural.
        if (widget.mapImage != null)
          Image(image: widget.mapImage!, fit: BoxFit.cover)
        else
          CustomPaint(painter: _MapPlaceholderPainter()),

        // 2. Línea punteada hogar→comercio (guiño al logo), dibujada al entrar.
        AnimatedBuilder(
          animation: _intro,
          builder: (context, _) => CustomPaint(
            painter: _ConnectionPainter(
              from: _pins[0].alignment,
              to: _pins[1].alignment,
              progress: _animate
                  ? Curves.easeInOut.transform(_intro.value)
                  : 1.0,
            ),
          ),
        ),

        // 3. Scrim para que el formulario siempre se lea (WCAG).
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                McColors.primary.withValues(alpha: 0.42),
                McColors.primaryDark.withValues(alpha: 0.80),
              ],
            ),
          ),
        ),

        // 4. Pines animados.
        for (var i = 0; i < _pins.length; i++)
          _AnimatedPin(
            spec: _pins[i],
            pulse: _pulse,
            intro: _intro,
            index: i,
            total: _pins.length,
            animate: _animate,
          ),

        // 5. Contenido (la Card del formulario).
        widget.child,
      ],
    );
  }
}

class _PinSpec {
  final Alignment alignment;
  final bool home;
  final bool brand;
  const _PinSpec(this.alignment, {this.home = false, this.brand = false});
}

class _AnimatedPin extends StatelessWidget {
  final _PinSpec spec;
  final Animation<double> pulse;
  final Animation<double> intro;
  final int index;
  final int total;
  final bool animate;

  const _AnimatedPin({
    required this.spec,
    required this.pulse,
    required this.intro,
    required this.index,
    required this.total,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    // Hogar en cobalto (primario), comercios en púrpura (acento). Manual de
    // marca: el cobalto domina, el púrpura acentúa.
    final color = spec.home ? McColors.primary : McColors.secondary;
    return Align(
      alignment: spec.alignment,
      child: AnimatedBuilder(
        animation: Listenable.merge([pulse, intro]),
        builder: (context, _) {
          // Entrada escalonada: cada pin arranca un poco después que el anterior.
          final start = (index / total) * 0.6;
          final raw = ((intro.value - start) / (1 - start)).clamp(0.0, 1.0);
          final scale = animate ? Curves.elasticOut.transform(raw) : 1.0;
          final pulseT = animate ? pulse.value : 0.0;
          return Opacity(
            opacity: raw.clamp(0.0, 1.0),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Halo pulsante.
                  Transform.scale(
                    scale: 0.6 + pulseT * 0.9,
                    child: Opacity(
                      opacity: (1 - pulseT) * 0.35,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  // Marcador: badge de marca (logo) para el pin destacado;
                  // teardrop genérico para el resto.
                  Transform.scale(
                    scale: scale,
                    child: spec.brand
                        ? _brandMark()
                        : Icon(
                            Icons.location_on,
                            color: color,
                            size: 34,
                            shadows: const [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Pin-badge de marca: el logo MC dentro de un círculo blanco con anillo
  /// púrpura y puntita. El logo (`pin_mc.png`) es opaco, el círculo blanco
  /// disimula su fondo.
  Widget _brandMark() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // puntita del marcador
        Positioned(
          bottom: 10,
          child: Transform.rotate(
            angle: 0.7853981634, // 45°
            child: Container(width: 12, height: 12, color: Colors.white),
          ),
        ),
        // círculo blanco con el logo + anillo púrpura
        Container(
          width: 46,
          height: 46,
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: McColors.secondary, width: 2.4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Image.asset(
            'assets/brand/pin_mc.png',
            package: 'mc_design_system',
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

/// Mapa procedural placeholder: manzanas, parques, una avenida y un río.
/// Es solo el telón de fondo mientras no haya imagen real; el scrim lo atenúa.
class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE7EBF6),
    );

    // Grilla de manzanas, levemente rotada para que se sienta orgánica.
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.10);
    canvas.translate(-size.width / 2, -size.height / 2);

    final pad = math.max(size.width, size.height);
    final area = Rect.fromLTWH(
      -pad * 0.5,
      -pad * 0.5,
      size.width + pad,
      size.height + pad,
    );

    final blockPaint = Paint()..color = Colors.white.withValues(alpha: 0.60);
    const step = 92.0;
    for (double y = area.top; y < area.bottom; y += step) {
      for (double x = area.left; x < area.right; x += step) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 7, y + 7, step - 14, step - 14),
            const Radius.circular(3),
          ),
          blockPaint,
        );
      }
    }

    // Parques (verde suave).
    final park = Paint()..color = const Color(0xFFB9D9B0).withValues(alpha: 0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.12, size.height * 0.18, step * 1.6, step * 1.2),
        const Radius.circular(6),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.60, step * 1.3, step * 1.1),
        const Radius.circular(6),
      ),
      park,
    );

    // Avenida principal (banda más ancha).
    final avenue = Paint()
      ..color = const Color(0xFFF3D9A6).withValues(alpha: 0.9)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(area.left, size.height * 0.34),
      Offset(area.right, size.height * 0.30),
      avenue,
    );

    canvas.restore();

    // Río (curva diagonal, sin rotar para que cruce natural).
    final river = Paint()
      ..color = const Color(0xFFAFC8E8).withValues(alpha: 0.85)
      ..strokeWidth = 26
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.05, -20)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.30,
        size.width * 0.15,
        size.height * 0.60,
        size.width * 0.40,
        size.height + 20,
      );
    canvas.drawPath(path, river);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Línea punteada entre dos pines, dibujada progresivamente ([progress] 0..1).
class _ConnectionPainter extends CustomPainter {
  final Alignment from;
  final Alignment to;
  final double progress;

  _ConnectionPainter({
    required this.from,
    required this.to,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset toOffset(Alignment a) =>
        Offset((a.x + 1) / 2 * size.width, (a.y + 1) / 2 * size.height);

    // Un toque hacia arriba para salir de la "cabeza" del pin.
    final start = toOffset(from) + const Offset(0, -6);
    final end = toOffset(to) + const Offset(0, -6);
    final current = Offset.lerp(start, end, progress.clamp(0.0, 1.0))!;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final total = (current - start).distance;
    if (total == 0) return;
    final dir = (current - start) / total;
    const dash = 9.0;
    const gap = 7.0;
    double d = 0;
    while (d < total) {
      final s = start + dir * d;
      final e = start + dir * math.min(d + dash, total);
      canvas.drawLine(s, e, paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter old) =>
      old.progress != progress || old.from != from || old.to != to;
}
