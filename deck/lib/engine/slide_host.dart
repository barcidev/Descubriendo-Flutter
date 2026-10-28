import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'deck_controller.dart';
import 'slide_info.dart';
import 'stage.dart';
import 'xray.dart';

/// Pinta la diapositiva actual y la transición desde la anterior.
///
/// Dentro de una sección, la nueva aparece subiendo un poco. Al cambiar de
/// sección, tres franjas a 45° (los azules de Flutter) barren la pantalla
/// y destapan la siguiente.
class SlideHost extends StatefulWidget {
  const SlideHost({required this.deck, super.key});

  final DeckController deck;

  @override
  State<SlideHost> createState() => _SlideHostState();
}

class _SlideHostState extends State<SlideHost>
    with SingleTickerProviderStateMixin {
  late final _transition = AnimationController(vsync: this, value: 1);

  /// Una llave por diapositiva: su estado sobrevive mientras sale.
  final _roots = <String, GlobalKey>{};

  late int _current = widget.deck.index;
  late int _currentStep = widget.deck.step;
  int? _previous;
  int _previousStep = 0;
  bool _wipe = false;
  int _direction = 1;
  int _run = 0;

  DeckController get _deck => widget.deck;

  @override
  void initState() {
    super.initState();
    _deck.addListener(_onDeck);
  }

  @override
  void didUpdateWidget(SlideHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deck != widget.deck) {
      oldWidget.deck.removeListener(_onDeck);
      widget.deck.addListener(_onDeck);
    }
  }

  @override
  void dispose() {
    _deck.removeListener(_onDeck);
    _transition.dispose();
    super.dispose();
  }

  void _onDeck() {
    final next = _deck.index;
    if (next == _current) {
      setState(() => _currentStep = _deck.step);
      return;
    }
    final reduced = Motion.reduced(context);
    final slides = _deck.slides;
    setState(() {
      _previous = _current;
      _previousStep = _currentStep;
      _current = next;
      _currentStep = _deck.step;
      _direction = _deck.direction;
      _wipe = !reduced && slides[next].section != slides[_previous!].section;
    });
    final run = ++_run;
    _transition.duration = _wipe
        ? Motion.wipe
        : (reduced ? Motion.quick : Motion.base);
    _transition.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted && run == _run) setState(() => _previous = null);
    });
  }

  Widget _slide(int index, int step) {
    final slide = _deck.slides[index];
    final root = _roots.putIfAbsent(slide.id, GlobalKey.new);
    return KeyedSubtree(
      key: ValueKey(slide.id),
      child: RepaintBoundary(
        key: root,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DeckBackground(),
            SlideInfo(
              slide: slide,
              startsSection: _deck.startsSection(index),
              child: Builder(builder: (context) => slide.builder(context, step)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previous = _previous;
    final current = _slide(_current, _currentStep);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (previous != null)
          AnimatedBuilder(
            animation: _transition,
            child: _slide(previous, _previousStep),
            builder: (context, child) {
              if (_wipe) return child!;
              final fade = 1 - const Interval(0, 0.55).transform(_transition.value);
              return Opacity(opacity: fade, child: child);
            },
          ),
        AnimatedBuilder(
          animation: _transition,
          child: current,
          builder: (context, child) {
            final t = _transition.value;
            if (previous == null || t >= 1) return child!;
            if (_wipe) {
              return ClipPath(
                clipper: _Revealed(_bands(t).last.$1, _direction),
                child: child,
              );
            }
            final rise = Motion.out.transform(t);
            return Opacity(
              opacity: const Interval(0.12, 1, curve: Curves.easeOut).transform(t),
              child: Transform.translate(
                offset: Offset(0, (1 - rise) * 18),
                child: child,
              ),
            );
          },
        ),
        if (previous != null && _wipe)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _transition,
              builder: (context, _) => CustomPaint(
                size: Canvas16x9.size,
                painter: _Beams(_bands(_transition.value), _direction),
              ),
            ),
          ),
        if (_deck.xray)
          XRayOverlay(root: _roots.putIfAbsent(
            _deck.slides[_current].id,
            GlobalKey.new,
          )),
      ],
    );
  }
}

/// Las franjas del barrido, de adelante hacia atrás: su borde trasero y su
/// borde delantero, medidos sobre la diagonal (x + y).
List<(double, double)> _bands(double t) {
  const widths = [150.0, 104.0, 72.0];
  const travel = Canvas16x9.width + Canvas16x9.height;
  final total = widths.reduce((a, b) => a + b);
  final bands = <(double, double)>[];
  var behind = 0.0;
  for (final (index, width) in widths.indexed) {
    // Cada franja sale un poco después: se separan como las del logo.
    final local = ((t - index * 0.005) / 0.99).clamp(0.0, 1.0);
    final front = Motion.inOut.transform(local) * (travel + total + 80) - behind;
    bands.add((front - width, front));
    behind += width;
  }
  return bands;
}

/// Lleva un punto del sistema «hacia adelante» al real: retroceder barre en
/// espejo, de derecha a izquierda.
Offset _orient(Offset point, int direction) =>
    direction >= 0 ? point : Offset(Canvas16x9.width - point.dx, point.dy);

/// La zona ya destapada: todo lo que quedó detrás de la última franja.
class _Revealed extends CustomClipper<Path> {
  const _Revealed(this.edge, this.direction);

  final double edge;
  final int direction;

  @override
  Path getClip(Size size) {
    const far = 6000.0;
    final points = [
      Offset(edge + far, -far),
      Offset(edge - far, far),
      const Offset(-3 * far, far),
      const Offset(-3 * far, -far),
    ].map((point) => _orient(point, direction)).toList();
    return Path()..addPolygon(points, true);
  }

  @override
  bool shouldReclip(_Revealed oldClipper) =>
      oldClipper.edge != edge || oldClipper.direction != direction;
}

class _Beams extends CustomPainter {
  const _Beams(this.bands, this.direction);

  final List<(double, double)> bands;
  final int direction;

  static const _colors = [FlutterBrand.sky, FlutterBrand.blue, FlutterBrand.navy];

  @override
  void paint(Canvas canvas, Size size) {
    const far = 6000.0;
    for (final (index, (back, front)) in bands.indexed) {
      final points = [
        Offset(back + far, -far),
        Offset(front + far, -far),
        Offset(front - far, far),
        Offset(back - far, far),
      ].map((point) => _orient(point, direction)).toList();
      canvas.drawPath(
        Path()..addPolygon(points, true),
        Paint()..color = _colors[index],
      );
    }
  }

  @override
  bool shouldRepaint(_Beams oldDelegate) => true;
}
