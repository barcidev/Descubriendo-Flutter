import 'package:flutter/widgets.dart';

import '../engine/overview.dart';
import '../theme/tokens.dart';

/// Aparece subiendo un poco cuando [visible] pasa a `true`, y se va igual.
class Reveal extends StatelessWidget {
  const Reveal({
    required this.visible,
    required this.child,
    this.from = const Offset(0, 0.12),
    this.duration = Motion.base,
    this.delay = Duration.zero,
    super.key,
  });

  final bool visible;
  final Widget child;

  /// De dónde llega, en fracciones de su propio tamaño.
  final Offset from;
  final Duration duration;

  /// Espera antes de moverse: varias juntas entran escalonadas.
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final instant = Motion.reduced(context) || Thumbnail.of(context);
    // La espera va dentro de la curva: así sigue siendo una animación
    // implícita, sin temporizadores.
    final fade = duration + delay;
    final slide = duration * 1.4 + delay;
    final start = delay.inMicroseconds;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: instant ? Duration.zero : fade,
        curve: Interval(start / fade.inMicroseconds, 1, curve: Motion.out),
        child: AnimatedSlide(
          offset: visible ? Offset.zero : from,
          duration: instant ? Duration.zero : slide,
          curve: Interval(
            start / slide.inMicroseconds,
            1,
            curve: Motion.emphasized,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Entra una sola vez, al construirse, después de [delay].
class EnterOnce extends StatefulWidget {
  const EnterOnce({
    required this.child,
    this.delay = Duration.zero,
    this.from = const Offset(0, 0.12),
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Offset from;

  @override
  State<EnterOnce> createState() => _EnterOnceState();
}

class _EnterOnceState extends State<EnterOnce> {
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shown) return;
    if (Motion.reduced(context) || Thumbnail.of(context)) {
      _shown = true;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) setState(() => _shown = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      Reveal(visible: _shown, from: widget.from, child: widget.child);
}
