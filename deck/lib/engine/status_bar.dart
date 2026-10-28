import 'package:material_ui/material_ui.dart';

import '../live/live_controller.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import 'deck_controller.dart';

/// La barra del pie, como la de un IDE: rama, comando de la sección,
/// progreso de la charla, público conectado y versiones.
class StatusBar extends StatelessWidget {
  const StatusBar({required this.deck, required this.live, super.key});

  final DeckController deck;
  final LiveController live;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = DeckType.monoSmall.copyWith(color: colors.faint);
    return ListenableBuilder(
      listenable: Listenable.merge([deck, live]),
      builder: (context, _) {
        final section = deck.slide.section;
        return Container(
          height: Space.statusBar,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: colors.canvas,
            border: Border(
              top: BorderSide(color: colors.line, width: Space.hairline),
            ),
          ),
          child: DefaultTextStyle(
            style: style,
            child: Row(
              children: [
                Icon(Icons.call_split, size: 18, color: colors.faint),
                const SizedBox(width: 8),
                const Text('main'),
                const SizedBox(width: 28),
                Text(
                  section.command,
                  style: style.copyWith(color: colors.accentText),
                ),
                Text('  ·  ${section.subtitle}'),
                const Spacer(),
                _Progress(deck: deck),
                const Spacer(),
                _LiveStatus(live: live),
                const SizedBox(width: 28),
                Text(
                  '${deck.index + 1}/${deck.slides.length}',
                  style: style.copyWith(fontFeatures: DeckType.tabular),
                ),
                const SizedBox(width: 28),
                const Text('Flutter 3.47 · Dart 3.13'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiveStatus extends StatelessWidget {
  const _LiveStatus({required this.live});

  final LiveController live;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final on = live.online || live.simulating;
    final label = switch ((live.online, live.simulating)) {
      (true, _) => '${live.connected} conectados',
      (false, true) => '${live.connected} conectados (ensayo)',
      _ => 'sin servidor · mano alzada',
    };
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? colors.success : colors.faint,
          ),
        ),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

/// Una franja inclinada por sección: llena las que ya pasaron y, a medias,
/// la actual.
class _Progress extends StatelessWidget {
  const _Progress({required this.deck});

  final DeckController deck;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sections = deck.sections;
    final current = deck.sectionIndexOf(deck.index);
    final inSection = [
      for (final (index, slide) in deck.slides.indexed)
        if (slide.section == deck.slide.section) index,
    ];
    final within = inSection.isEmpty
        ? 0.0
        : (inSection.indexOf(deck.index) + 1) / inSection.length;
    return CustomPaint(
      size: Size(sections.length * 34.0, 10),
      painter: _ProgressPainter(
        count: sections.length,
        current: current,
        within: within,
        done: colors.accent,
        todo: colors.line,
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter({
    required this.count,
    required this.current,
    required this.within,
    required this.done,
    required this.todo,
  });

  final int count;
  final int current;
  final double within;
  final Color done;
  final Color todo;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 6.0;
    final width = size.width / count;
    final height = size.height;
    Path slanted(double left, double right) => Path()
      ..moveTo(left + height, 0)
      ..lineTo(right, 0)
      ..lineTo(right - height, height)
      ..lineTo(left, height)
      ..close();
    for (var index = 0; index < count; index++) {
      final left = index * width;
      final right = left + width - gap;
      canvas.drawPath(slanted(left, right), Paint()..color = todo);
      final fill = index < current ? 1.0 : (index == current ? within : 0.0);
      if (fill > 0) {
        canvas.drawPath(
          slanted(left, left + (right - left) * fill),
          Paint()..color = done,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.current != current ||
      oldDelegate.within != within ||
      oldDelegate.done != done ||
      oldDelegate.todo != todo;
}
