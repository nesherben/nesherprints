import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nesherprints/core/theme/app_colors.dart';

/// Bobina de filamento del color indicado. Gira unas vueltas cuando
/// [spinToken] cambia a un valor mayor que 0 (p. ej. al añadir un color) y
/// también al construirse si ya viene con un token.
class SpoolIcon extends StatefulWidget {
  const SpoolIcon({
    super.key,
    required this.color,
    this.size = 44,
    this.spinToken = 0,
  });

  final Color color;
  final double size;
  final int spinToken;

  @override
  State<SpoolIcon> createState() => _SpoolIconState();
}

class _SpoolIconState extends State<SpoolIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinToken > 0) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(SpoolIcon old) {
    super.didUpdateWidget(old);
    if (widget.spinToken > 0 && widget.spinToken != old.spinToken) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        // Arranca rápido y frena: dos vueltas y media.
        final turns = Curves.easeOutCubic.transform(_controller.value) * 2.5;
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _SpoolPainter(
            color: widget.color,
            angle: turns * 2 * math.pi,
          ),
        );
      },
    );
  }
}

class _SpoolPainter extends CustomPainter {
  _SpoolPainter({required this.color, required this.angle});

  final Color color;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);

    // Brida exterior.
    canvas.drawCircle(Offset.zero, r, Paint()..color = AppColors.surfaceHigh);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..color = AppColors.border,
    );

    // Filamento enrollado.
    final wound = Paint()..color = color;
    canvas.drawCircle(Offset.zero, r * 0.84, wound);
    // Vueltas del hilo: anillos algo más oscuros para que se note el giro.
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.04
      ..color = Colors.black.withValues(alpha: 0.18);
    for (final f in [0.52, 0.64, 0.76]) {
      canvas.drawCircle(Offset.zero, r * f, line);
    }
    // Una marca radial para ver la rotación.
    canvas.drawLine(
      Offset(r * 0.40, 0),
      Offset(r * 0.84, 0),
      Paint()
        ..strokeWidth = r * 0.07
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    // Núcleo con agujero y radios.
    canvas.drawCircle(
      Offset.zero,
      r * 0.36,
      Paint()..color = AppColors.surfaceHigh,
    );
    final hole = Paint()..color = AppColors.background;
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.rotate(i * 2 * math.pi / 3);
      canvas.drawCircle(Offset(r * 0.22, 0), r * 0.07, hole);
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, r * 0.10, hole);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpoolPainter old) =>
      old.color != color || old.angle != angle;
}
