import 'package:flutter/widgets.dart';

import '../theme/deck_theme.dart';
import '../theme/tokens.dart';

/// Las guías del Inspector de Flutter como adorno: una línea cian alrededor
/// del contenido, marcas en las esquinas y su tamaño real en píxeles.
class GuideBox extends StatelessWidget {
  const GuideBox({
    required this.child,
    this.label,
    this.showSize = true,
    this.outset = 14,
    super.key,
  });

  final Widget child;

  /// Un nombre arriba a la izquierda, como `Column` o `Text`.
  final String? label;
  final bool showSize;

  /// Cuánto se separa la guía del contenido.
  final double outset;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _GuidePainter(
        color: context.colors.guide,
        label: label,
        showSize: showSize,
        outset: outset,
      ),
      child: child,
    );
  }
}

class _GuidePainter extends CustomPainter {
  const _GuidePainter({
    required this.color,
    required this.label,
    required this.showSize,
    required this.outset,
  });

  final Color color;
  final String? label;
  final bool showSize;
  final double outset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).inflate(outset);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.42);
    canvas.drawRect(rect, line);

    // Marcas que se salen de cada esquina, como en una herramienta de diseño.
    final tick = Paint()
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.75);
    const reach = 16.0;
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      final dx = corner.dx == rect.left ? -reach : reach;
      final dy = corner.dy == rect.top ? -reach : reach;
      canvas
        ..drawLine(corner, corner.translate(dx, 0), tick)
        ..drawLine(corner, corner.translate(0, dy), tick);
    }

    final style = TextStyle(
      fontFamily: DeckFonts.mono,
      fontSize: 15,
      color: color.withValues(alpha: 0.85),
      fontFeatures: DeckType.tabular,
    );
    if (showSize) {
      final text = TextPainter(
        text: TextSpan(
          text:
              '${size.width.toStringAsFixed(1)} × ${size.height.toStringAsFixed(1)}',
          style: style,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset(rect.right - text.width, rect.top - text.height - 6),
      );
    }
    if (label case final label?) {
      final text = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(rect.left, rect.top - text.height - 6));
    }
  }

  @override
  bool shouldRepaint(_GuidePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.label != label ||
      oldDelegate.showSize != showSize ||
      oldDelegate.outset != outset;
}
