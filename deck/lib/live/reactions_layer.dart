import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'live_controller.dart';

/// Las reacciones del público suben flotando por el borde derecho, como
/// burbujas, y se desvanecen. Nunca tapan el centro de la diapositiva.
class ReactionsLayer extends StatefulWidget {
  const ReactionsLayer({required this.live, super.key});

  final LiveController live;

  @override
  State<ReactionsLayer> createState() => _ReactionsLayerState();
}

class _Bubble {
  _Bubble(this.icon, this.color, this.born, this.x, this.drift);

  final IconData icon;
  final Color color;
  final Duration born;
  final double x;
  final double drift;
}

class _ReactionsLayerState extends State<ReactionsLayer>
    with SingleTickerProviderStateMixin {
  static const _life = Duration(milliseconds: 2600);
  static const _max = 36;

  final _bubbles = <_Bubble>[];
  final _random = math.Random();
  late final Ticker _ticker = createTicker(_onTick);
  Duration _now = Duration.zero;
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.live.reactions.listen(_add);
  }

  void _add(String kind) {
    if (_bubbles.length >= _max) return;
    final (icon, color) = switch (kind) {
      'fuego' => (Icons.local_fire_department, const Color(0xFFFF8A3D)),
      'bug' => (Icons.bug_report, const Color(0xFF1CDAC5)),
      _ => (Icons.celebration, const Color(0xFFFFD25E)),
    };
    _bubbles.add(
      _Bubble(icon, color, _now, 1690 + _random.nextDouble() * 150, _random.nextDouble() * 2 - 1),
    );
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    setState(() {
      _now = elapsed;
      _bubbles.removeWhere((bubble) => elapsed - bubble.born > _life);
    });
    if (_bubbles.isEmpty) {
      _ticker.stop();
      _now = Duration.zero;
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final bubble in _bubbles)
            Builder(
              builder: (context) {
                final t = ((_now - bubble.born).inMilliseconds / _life.inMilliseconds).clamp(0.0, 1.0);
                final rise = Curves.easeOutCubic.transform(t);
                return Positioned(
                  left: bubble.x + math.sin(t * math.pi * 2) * 18 * bubble.drift,
                  top: 980 - rise * 640,
                  child: Opacity(
                    opacity: t < 0.15 ? t / 0.15 : (1 - t) / 0.85,
                    child: Transform.scale(
                      scale: 0.7 + rise * 0.5,
                      child: Icon(bubble.icon, size: 54, color: bubble.color),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
