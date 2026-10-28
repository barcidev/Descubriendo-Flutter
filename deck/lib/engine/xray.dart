import 'dart:async';

import 'package:flutter/widgets.dart';

import '../theme/deck_theme.dart';
import '../theme/tokens.dart';

/// Rayos X: recorre el árbol real de la diapositiva y dibuja una caja por
/// cada widget que vale la pena ver, con su nombre. No es una imagen: si la
/// diapositiva cambia, las cajas cambian con ella.
class XRayOverlay extends StatefulWidget {
  const XRayOverlay({required this.root, super.key});

  final GlobalKey root;

  @override
  State<XRayOverlay> createState() => _XRayOverlayState();
}

enum _Kind { layout, box, content, ours }

const _layout = {
  'Row', 'Column', 'Stack', 'Wrap', 'Flex', 'ListView', 'GridView', //
  'Positioned', 'Align', 'Center', 'Expanded', 'Flexible', 'Spacer',
  'SingleChildScrollView', 'PageView', 'Table', 'Scaffold',
};

const _box = {
  'Padding', 'SizedBox', 'Container', 'DecoratedBox', 'ConstrainedBox', //
  'AspectRatio', 'FittedBox', 'ClipRRect', 'ClipPath', 'Transform',
  'Opacity', 'ColoredBox', 'AnimatedContainer', 'AnimatedOpacity',
};

const _content = {
  'Text', 'Icon', 'Image', 'CustomPaint', 'Card', 'FilledButton', //
  'TextButton', 'ElevatedButton', 'OutlinedButton', 'IconButton',
  'ListTile', 'CircleAvatar', 'Chip', 'Divider', 'Switch', 'Checkbox',
  'Slider', 'TextField', 'CircularProgressIndicator', 'FlutterLogo',
};

/// Los widgets hechos a mano para esta charla.
const _ours = {
  'CodeBlock', 'Terminal', 'PollView', 'GuideBox', 'SlideScaffold', //
  'SectionChip', 'OverflowStripes', 'QrCode', 'JoinCard', 'ExcuseCard',
  'AgendaPreview', 'QuizCard', 'Reveal', 'FlutterLockup',
};

_Kind? _kindOf(String name) {
  if (_ours.contains(name)) return _Kind.ours;
  if (_layout.contains(name)) return _Kind.layout;
  if (_box.contains(name)) return _Kind.box;
  if (_content.contains(name)) return _Kind.content;
  return null;
}

class _Box {
  const _Box(this.rect, this.name, this.kind, {this.hidden = 0});

  final Rect rect;
  final String name;
  final _Kind kind;

  /// Cuántos widgets más ocupan exactamente la misma caja.
  final int hidden;

  String get label => hidden == 0 ? name : '$name +$hidden';
}

class _XRayOverlayState extends State<XRayOverlay> {
  List<_Box> _boxes = const [];
  int _elements = 0;
  Timer? _rescan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
    // Lo que se anima se mueve: las cajas lo siguen de cerca.
    _rescan = Timer.periodic(
      const Duration(milliseconds: 350),
      (_) => _scan(),
    );
  }

  @override
  void didUpdateWidget(XRayOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.root != widget.root) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
    }
  }

  @override
  void dispose() {
    _rescan?.cancel();
    super.dispose();
  }

  void _scan() {
    if (!mounted) return;
    final root = widget.root.currentContext;
    final rootBox = root?.findRenderObject();
    if (root is! Element || rootBox is! RenderBox || !rootBox.hasSize) return;
    final bounds = Offset.zero & rootBox.size;
    final boxes = <_Box>[];
    var elements = 0;

    void visit(Element element) {
      elements++;
      final name = element.widget.runtimeType.toString();
      final kind = _kindOf(name);
      final renderObject = kind == null ? null : element.renderObject;
      if (kind != null &&
          renderObject is RenderBox &&
          renderObject.attached &&
          renderObject.hasSize &&
          boxes.length < 360) {
        final rect = MatrixUtils.transformRect(
          renderObject.getTransformTo(rootBox),
          Offset.zero & renderObject.size,
        );
        final coversAll = rect.width * rect.height > bounds.width * bounds.height * 0.9;
        if (rect.width >= 4 &&
            rect.height >= 4 &&
            !coversAll &&
            bounds.overlaps(rect)) {
          boxes.add(_Box(rect, name, kind));
        }
      }
      element.visitChildren(visit);
    }

    root.visitChildren(visit);
    // Un widget suele envolver a otro del mismo tamaño (Transform dentro de
    // Opacity dentro de…): se nombra el de afuera y se cuentan los demás.
    final grouped = <(int, int, int, int), _Box>{};
    for (final box in boxes) {
      final key = (
        box.rect.left.round(),
        box.rect.top.round(),
        box.rect.width.round(),
        box.rect.height.round(),
      );
      final first = grouped[key];
      grouped[key] = first == null
          ? box
          : _Box(first.rect, first.name, first.kind, hidden: first.hidden + 1);
    }
    setState(() {
      _boxes = grouped.values.toList();
      _elements = elements;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = {
      _Kind.layout: colors.guide,
      _Kind.box: const Color(0xFFFFD25E),
      _Kind.content: colors.success,
      _Kind.ours: const Color(0xFFFF8FD8),
    };
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _XRayPainter(_boxes, palette)),
          Positioned(
            top: 28,
            right: 32,
            child: _Legend(
              widgets: _boxes.length,
              elements: _elements,
              palette: palette,
            ),
          ),
        ],
      ),
    );
  }
}

class _XRayPainter extends CustomPainter {
  _XRayPainter(this.boxes, this.palette);

  final List<_Box> boxes;
  final Map<_Kind, Color> palette;

  static const _label = TextStyle(
    fontFamily: DeckFonts.mono,
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: Color(0xFF03101F),
  );

  @override
  void paint(Canvas canvas, Size size) {
    // Varias cajas empiezan en la misma esquina: sus nombres se corren.
    final usedSlots = <(int, int), double>{};
    for (final box in boxes) {
      final color = palette[box.kind]!;
      canvas.drawRect(
        box.rect.deflate(0.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: 0.9),
      );
      final text = TextPainter(
        text: TextSpan(text: box.label, style: _label),
        textDirection: TextDirection.ltr,
      )..layout();
      final slot = (box.rect.left ~/ 6, box.rect.top ~/ 6);
      final shift = usedSlots[slot] ?? 0;
      usedSlots[slot] = shift + text.width + 12;
      final chip = Rect.fromLTWH(
        box.rect.left + shift,
        box.rect.top,
        text.width + 10,
        text.height + 4,
      );
      canvas.drawRect(chip, Paint()..color = color);
      text.paint(canvas, chip.topLeft + const Offset(5, 2));
    }
  }

  @override
  bool shouldRepaint(_XRayPainter oldDelegate) =>
      oldDelegate.boxes != boxes || oldDelegate.palette != palette;
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.widgets,
    required this.elements,
    required this.palette,
  });

  final int widgets;
  final int elements;
  final Map<_Kind, Color> palette;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: DeckFonts.mono,
      fontSize: 17,
      height: 1.5,
      color: Color(0xFFEAF2FF),
    );
    Widget key(_Kind kind, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: palette[kind]),
        const SizedBox(width: 10),
        Text(label, style: style),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEE020814),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: const Color(0xFF1E3A66)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 22, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RAYOS X',
              style: style.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: palette[_Kind.layout],
              ),
            ),
            Text('$widgets widgets a la vista', style: style),
            Text('$elements elementos en el árbol', style: style),
            const SizedBox(height: 8),
            key(_Kind.layout, 'layout'),
            key(_Kind.box, 'caja y espacio'),
            key(_Kind.content, 'contenido'),
            key(_Kind.ours, 'hecho para esta charla'),
          ],
        ),
      ),
    );
  }
}
