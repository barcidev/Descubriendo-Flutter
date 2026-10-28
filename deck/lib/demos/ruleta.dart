import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../engine/overview.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';

/// Los sospechosos de siempre: cómo van en la ruleta y cómo se dice el
/// veredicto. La ruleta escoge uno cada pocos segundos.
const culprits = [
  ('el DNS', 'del DNS'),
  ('la caché', 'de la caché'),
  ('el pasante', 'del pasante'),
  ('Air-e', 'de Air-e'),
  ('el arroyo', 'del arroyo'),
  ('el wifi', 'del wifi'),
  ('Mercurio', 'de Mercurio retrógrado'),
  ('el merge', 'del último merge'),
];

/// La ruleta de la culpa: gira mientras el público escribe sus excusas y
/// cae en un culpable distinto cada vez.
class BlameWheel extends StatefulWidget {
  const BlameWheel({this.size = 520, super.key});

  final double size;

  @override
  State<BlameWheel> createState() => _BlameWheelState();
}

class _BlameWheelState extends State<BlameWheel>
    with SingleTickerProviderStateMixin {
  // Cada vuelta: cuatro segundos girando y uno y medio mostrando al culpable.
  static const _spin = Duration(milliseconds: 4000);
  static const _hold = Duration(milliseconds: 1500);

  late final _controller = AnimationController(vsync: this, duration: _spin + _hold);
  final _random = math.Random(11);
  double _from = 0;
  double _to = 0;
  int _culprit = 0;

  @override
  void initState() {
    super.initState();
    _next();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _next();
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Thumbnail.of(context) || Motion.reduced(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  /// Escoge el próximo culpable y cuánto girar para que quede bajo la flecha.
  void _next() {
    var culprit = _random.nextInt(culprits.length);
    if (culprit == _culprit) culprit = (culprit + 1) % culprits.length;
    _culprit = culprit;
    final slice = 2 * math.pi / culprits.length;
    // La flecha está arriba: el centro de la tajada debe quedar en -π/2.
    final target = -math.pi / 2 - (culprit + 0.5) * slice;
    _from = _to % (2 * math.pi);
    var delta = (target - _from) % (2 * math.pi);
    delta += 2 * math.pi * 3;
    _to = _from + delta;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spinShare = _spin.inMilliseconds / (_spin + _hold).inMilliseconds;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = (_controller.value / spinShare).clamp(0.0, 1.0);
        final angle = _from + (_to - _from) * Curves.easeOutQuart.transform(t);
        final landed = _controller.value >= spinShare;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: widget.size,
              child: CustomPaint(
                painter: _WheelPainter(
                  angle: angle,
                  highlight: landed ? _culprit : null,
                  colors: colors,
                ),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 52,
              child: AnimatedSwitcher(
                duration: Motion.quick,
                child: Text(
                  landed ? 'Fue culpa ${culprits[_culprit].$2}' : 'Buscando culpable…',
                  key: ValueKey(landed ? _culprit : -1),
                  style: DeckType.headline.copyWith(
                    fontSize: 38,
                    color: landed ? colors.accentText : colors.muted,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({required this.angle, required this.highlight, required this.colors});

  final double angle;
  final int? highlight;
  final DeckColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 18;
    final slice = 2 * math.pi / culprits.length;
    const tones = [FlutterBrand.navy, FlutterBrand.blue, Color(0xFF0B2447), Color(0xFF02569B)];
    for (var i = 0; i < culprits.length; i++) {
      final start = angle + i * slice;
      final paint = Paint()
        ..color = i == highlight ? FlutterBrand.sky : tones[i % tones.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, slice, true, paint);
      // El nombre va a lo largo del radio, del centro hacia afuera.
      final label = TextPainter(
        text: TextSpan(
          text: culprits[i].$1,
          style: TextStyle(
            fontFamily: DeckFonts.sans,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFFFFF).withValues(alpha: i == highlight ? 1 : 0.85),
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: radius - 70);
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(start + slice / 2)
        ..translate(radius - 24 - label.width, -label.height / 2);
      label.paint(canvas, Offset.zero);
      canvas.restore();
    }
    // Bordes, centro y la flecha de arriba.
    canvas
      ..drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = colors.line,
      )
      ..drawCircle(center, 46, Paint()..color = colors.canvas)
      ..drawCircle(
        center,
        46,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = FlutterBrand.sky,
      );
    final arrow = Path()
      ..moveTo(center.dx - 22, 0)
      ..lineTo(center.dx + 22, 0)
      ..lineTo(center.dx, 40)
      ..close();
    canvas.drawPath(arrow, Paint()..color = const Color(0xFFFFD25E));
    final bug = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.bug_report.codePoint),
        style: TextStyle(
          fontFamily: Icons.bug_report.fontFamily,
          package: Icons.bug_report.fontPackage,
          fontSize: 48,
          color: FlutterBrand.sky,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    bug.paint(canvas, center - Offset(bug.width / 2, bug.height / 2));
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.highlight != highlight || oldDelegate.colors != colors;
}
