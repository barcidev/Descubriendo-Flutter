import 'package:flutter/widgets.dart';

import '../theme/deck_theme.dart';
import '../theme/tokens.dart';

/// El lienzo de 1920 × 1080. Se escala entero al tamaño de la ventana, así
/// que la charla se ve igual en un portátil que en un proyector 4K.
class Stage extends StatelessWidget {
  const Stage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF000000),
      child: Center(
        child: FittedBox(
          child: SizedBox.fromSize(
            size: Canvas16x9.size,
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}

/// El fondo de cada diapositiva: el color del tema y una cuadrícula de
/// puntos, como el lienzo de una herramienta de diseño.
class DeckBackground extends StatelessWidget {
  const DeckBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomPaint(
      painter: _DotGrid(background: colors.canvas, dot: colors.grid),
      size: Canvas16x9.size,
    );
  }
}

class _DotGrid extends CustomPainter {
  const _DotGrid({required this.background, required this.dot});

  final Color background;
  final Color dot;

  static const _spacing = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()..color = dot;
    for (var y = _spacing / 2; y < size.height; y += _spacing) {
      for (var x = _spacing / 2; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), 1.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGrid oldDelegate) =>
      oldDelegate.background != background || oldDelegate.dot != dot;
}
