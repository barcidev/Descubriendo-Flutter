import 'package:material_ui/material_ui.dart';

import '../engine/slide.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/blocks.dart';
import '../ui/reveal.dart';
import '../ui/slide_scaffold.dart';
import '../ui/terminal.dart';
import 'sections.dart';

final runSlides = [
  Slide(
    id: 'demo',
    section: runSection,
    title: 'La demo',
    steps: 2,
    builder: (context, step) => _Demo(step: step),
  ),
];

const _runLines = [
  TermLine.command('flutter run -d "iPhone 16e"'),
  TermLine('Launching lib/main.dart on iPhone 16e in debug mode...', pause: Duration(milliseconds: 400)),
  TermLine('Xcode build done.                                           38,1s', pause: Duration(milliseconds: 900)),
  TermLine('r Hot reload. {fire}{fire}{fire}', tone: TermTone.accent),
];

/// La única diapositiva que habla de EcoEats: la app real del final.
class _Demo extends StatelessWidget {
  const _Demo({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'Todo esto, en una app real: EcoEats',
      lead: 'Flutter en el celular, una API en Kotlin (Spring Boot) en la nube.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Terminal(lines: _runLines, title: 'zsh · demo', fontSize: 22),
                const SizedBox(height: 36),
                Reveal(
                  visible: step >= 1,
                  child: const Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      Tag('3 días'),
                      Tag('213 commits'),
                      Tag('96 widgets propios'),
                      Tag('407 tests'),
                      Tag('español e inglés'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 56),
          Expanded(
            flex: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lo que vamos a ver', style: DeckType.monoLabel.copyWith(color: colors.accentText)),
                const SizedBox(height: 22),
                const PointList(
                  gap: 14,
                  style: TextStyle(fontSize: 30, height: 1.25),
                  points: [
                    ('Login con JWT contra la API en Kotlin', null),
                    ('Catálogo, búsqueda sin tildes y filtros', null),
                    ('Animaciones entre pantallas', null),
                    ('Tema claro y oscuro, español e inglés', null),
                    ('Los estados tristes: sin red, 429, sesión vencida', null),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
