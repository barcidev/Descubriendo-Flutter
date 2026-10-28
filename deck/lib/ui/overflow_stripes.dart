import 'package:flutter/widgets.dart';

/// La franja amarilla y negra con la que Flutter avisa, en modo debug, que
/// algo no cupo. Mismos colores y misma etiqueta: rojo oscuro sobre blanco.
class OverflowStripes extends StatelessWidget {
  const OverflowStripes({
    required this.label,
    this.height = 30,
    super.key,
  });

  final String label;
  final double height;

  // Los colores de `DebugOverflowIndicatorMixin`.
  static const _black = Color(0xBF000000);
  static const _yellow = Color(0xBFFFFF00);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _Stripes()),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: const Color(0xFFFFFFFF),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'GoogleSansCode',
                  fontSize: 17,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF900000),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stripes extends CustomPainter {
  const _Stripes();

  @override
  void paint(Canvas canvas, Size size) {
    const stripe = 14.0;
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..drawRect(Offset.zero & size, Paint()..color = OverflowStripes._black);
    final yellow = Paint()..color = OverflowStripes._yellow;
    for (var x = -size.height; x < size.width + size.height; x += stripe * 2) {
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..lineTo(x + size.height, 0)
          ..lineTo(x + size.height + stripe, 0)
          ..lineTo(x + stripe, size.height)
          ..close(),
        yellow,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Stripes oldDelegate) => false;
}
