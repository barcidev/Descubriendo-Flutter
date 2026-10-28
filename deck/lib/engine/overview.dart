import 'package:flutter/widgets.dart';

import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import 'deck_controller.dart';
import 'slide_info.dart';
import 'stage.dart';

/// Avisa a las diapositivas que se están pintando en miniatura (vista
/// general, capturas): lo que se anima solo llega directo a su final.
class Thumbnail extends InheritedWidget {
  const Thumbnail({required super.child, super.key});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Thumbnail>() != null;

  @override
  bool updateShouldNotify(Thumbnail oldWidget) => false;
}

/// Todas las diapositivas en una cuadrícula (tecla O). Un clic salta a esa.
class Overview extends StatelessWidget {
  const Overview({required this.deck, super.key});

  final DeckController deck;

  static const _columns = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const gap = 20.0;
    const width = (Canvas16x9.width - 2 * 80 - (_columns - 1) * gap) / _columns;
    return ColoredBox(
      color: colors.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(80, 64, 80, 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vista general · ${deck.slides.length} diapositivas',
              style: DeckType.monoLabel.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: gap,
              runSpacing: 18,
              children: [
                for (final (index, slide) in deck.slides.indexed)
                  GestureDetector(
                    onTap: () => deck.goTo(index),
                    child: SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DecoratedBox(
                            position: DecorationPosition.foreground,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: index == deck.index
                                    ? colors.accent
                                    : colors.line,
                                width: index == deck.index ? 3 : 1,
                              ),
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: IgnorePointer(
                                child: FittedBox(
                                  child: SizedBox.fromSize(
                                    size: Canvas16x9.size,
                                    child: Thumbnail(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          const DeckBackground(),
                                          SlideInfo(
                                            slide: slide,
                                            startsSection: false,
                                            child: Builder(
                                              builder: (context) =>
                                                  slide.builder(
                                                    context,
                                                    slide.steps - 1,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${index + 1}. ${slide.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DeckType.monoSmall.copyWith(
                              fontSize: 14,
                              color: slide.skippable
                                  ? colors.faint
                                  : colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
