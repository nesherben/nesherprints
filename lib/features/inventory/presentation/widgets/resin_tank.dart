import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/features/inventory/domain/resin_blend.dart';

/// Tanque de resina: el nivel sube o baja con una animación de líquido y,
/// cuando se añade, cae un hilo de resina desde arriba. En reposo el líquido
/// queda quieto (la animación es finita).
class ResinTank extends StatefulWidget {
  const ResinTank({
    super.key,
    required this.stockGrams,
    this.width = 120,
    this.height = 170,
  });

  final double stockGrams;
  final double width;
  final double height;

  @override
  State<ResinTank> createState() => _ResinTankState();
}

class _ResinTankState extends State<ResinTank>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  double _from = 0;
  double _to = 0;
  bool _pouring = false;

  /// Nivel que se está dibujando ahora.
  double get _current {
    final t = Curves.easeInOutCubic.transform(_controller.value);
    return _from + (_to - _from) * t;
  }

  @override
  void initState() {
    super.initState();
    _to = ResinBlend.level(widget.stockGrams);
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(ResinTank old) {
    super.didUpdateWidget(old);
    final target = ResinBlend.level(widget.stockGrams);
    if ((target - _to).abs() < 0.0005) return;
    _from = _current;
    _pouring = target > _to;
    _to = target;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tanque de resina',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _TankPainter(
            level: _current,
            t: _controller.value,
            pouring: _pouring,
            animating: _controller.isAnimating,
          ),
        ),
      ),
    );
  }
}

class _TankPainter extends CustomPainter {
  _TankPainter({
    required this.level,
    required this.t,
    required this.pouring,
    required this.animating,
  });

  final double level;
  final double t;
  final bool pouring;
  final bool animating;

  @override
  void paint(Canvas canvas, Size size) {
    final tank = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 14, size.width - 12, size.height - 20),
      const Radius.circular(18),
    );

    // Fondo del cristal.
    canvas.drawRRect(tank, Paint()..color = AppColors.surfaceHigh);

    final inner = tank.deflate(3);
    canvas.save();
    canvas.clipRRect(inner);

    final surfaceY = inner.bottom - inner.height * level;
    // Las olas se calman al terminar la animación.
    final energy = animating ? math.sin(math.pi * t).clamp(0.0, 1.0) : 0.0;
    final amplitude = 1.5 + 5 * energy;
    final phase = t * 2 * math.pi * 3;

    Path wave(double offset, double amp, double shift) {
      final p = Path()..moveTo(inner.left, inner.bottom);
      for (double x = inner.left; x <= inner.right; x += 2) {
        final y =
            surfaceY +
            offset +
            amp *
                math.sin((x / inner.width) * 2 * math.pi * 1.5 + phase + shift);
        p.lineTo(x, y);
      }
      return p
        ..lineTo(inner.right, inner.bottom)
        ..close();
    }

    if (level > 0.001) {
      // Ola de fondo, más clara y desfasada.
      canvas.drawPath(
        wave(-2, amplitude, 1.6),
        Paint()..color = AppColors.resinText.withValues(alpha: 0.45),
      );
      // Cuerpo del líquido con degradado.
      final body = wave(0, amplitude * 0.8, 0);
      canvas.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.resin.withValues(alpha: 0.95),
              AppColors.resin.withValues(alpha: 0.65),
            ],
          ).createShader(inner.outerRect),
      );

      // Burbujas mientras se mueve.
      if (animating) {
        final bubble = Paint()..color = Colors.white.withValues(alpha: 0.25);
        for (var i = 0; i < 5; i++) {
          final x = inner.left + inner.width * (0.18 + 0.16 * i);
          final rise = ((t * 1.6 + i * 0.23) % 1.0);
          final y = inner.bottom - (inner.bottom - surfaceY) * rise;
          canvas.drawCircle(Offset(x, y), 1.5 + (i % 3), bubble);
        }
      }
    }

    // Hilo de resina cayendo desde arriba.
    if (pouring && animating && t < 0.75) {
      final fade = (1 - t / 0.75).clamp(0.0, 1.0);
      final stream = Paint()
        ..color = AppColors.resin.withValues(alpha: 0.9 * fade)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      final x = inner.center.dx;
      canvas.drawLine(
        Offset(x, inner.top - 6),
        Offset(x, surfaceY + 2),
        stream,
      );
    }
    canvas.restore();

    // Marcas de nivel (25 / 50 / 75 %).
    final tick = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.5;
    for (final f in [0.25, 0.5, 0.75]) {
      final y = inner.bottom - inner.height * f;
      canvas.drawLine(
        Offset(inner.right - 14, y),
        Offset(inner.right - 2, y),
        tick,
      );
    }

    // Borde del tanque y tapa.
    canvas.drawRRect(
      tank,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.border,
    );
    final lid = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.22, 4, size.width * 0.56, 12),
      const Radius.circular(5),
    );
    canvas.drawRRect(lid, Paint()..color = AppColors.border);

    // Brillo del cristal.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tank.left + 9, tank.top + 18, 5, tank.height * 0.45),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(_TankPainter old) =>
      old.level != level ||
      old.t != t ||
      old.pouring != pouring ||
      old.animating != animating;
}
