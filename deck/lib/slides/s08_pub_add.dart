import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../engine/slide.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/blocks.dart';
import '../ui/qr_code.dart';
import '../ui/reveal.dart';
import '../ui/slide_scaffold.dart';
import 'sections.dart';

final pubAddSlides = [
  Slide(
    id: 'recomendaciones',
    section: pubAddSection,
    title: 'Recomendaciones',
    steps: 4,
    builder: (context, step) => _Advice(step: step),
  ),
  Slide(
    id: 'por-donde-empezar',
    section: pubAddSection,
    title: 'Por dónde empezar',
    builder: (context, step) => const _WhereToStart(),
  ),
];

const _advice = [
  (
    'Antes de empezar',
    [
      ('Fija la versión de Flutter', 'fvm: que nadie diga «en mi máquina era otra».'),
      ('Lints estrictos desde el día 1', 'El analizador es tu primer code review.'),
      ('Carpetas por funcionalidad', 'No por tipo de archivo.'),
    ],
  ),
  (
    'Mientras construyes',
    [
      ('Un solo gestor de estado', 'El que sea, pero uno.'),
      ('Modelos inmutables, errores con tipo', 'sealed + switch: el compilador te cuida.'),
      ('Diseña los estados tristes', 'Cargando, vacío, error, sin red.'),
      ('Accesibilidad e idiomas desde el inicio', 'Después cuesta el triple.'),
    ],
  ),
  (
    'Antes de publicar',
    [
      ('Prueba en celulares reales', 'iOS y Android, no solo el emulador.'),
      ('Mide con DevTools antes de optimizar', 'Adivinar no es medir.'),
      ('const donde se pueda', 'prefer_const_constructors te va a perseguir.'),
    ],
  ),
];

class _Advice extends StatelessWidget {
  const _Advice({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'Lo que me hubiera gustado saber antes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Tag('#0', filled: true),
              const SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '¿Ya probaste '),
                    TextSpan(
                      text: 'flutter clean',
                      style: DeckType.mono.copyWith(fontSize: 34, color: colors.accentText),
                    ),
                    const TextSpan(text: '? (El «apaga y vuelve a prender» de Flutter.)'),
                  ],
                ),
                style: DeckType.headline.copyWith(fontSize: 34, color: colors.ink),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, (group, tips)) in _advice.indexed) ...[
                  if (index > 0) const SizedBox(width: 36),
                  Expanded(
                    child: Reveal(
                      visible: step > index,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group, style: DeckType.monoLabel.copyWith(color: colors.accentText)),
                          const SizedBox(height: 20),
                          for (final (tip, detail) in tips)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tip, style: DeckType.small.copyWith(fontSize: 29, color: colors.ink)),
                                  const SizedBox(height: 4),
                                  Text(detail, style: DeckType.caption.copyWith(color: colors.muted)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhereToStart extends StatelessWidget {
  const _WhereToStart();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const start = 'https://docs.flutter.dev/get-started';
    return SlideScaffold(
      title: 'Por dónde empezar mañana',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: PointList(
              gap: 20,
              points: [
                ('DartPad', 'dartpad.dev: Flutter en el navegador, sin instalar nada.'),
                ('El codelab oficial', '«Your first Flutter app», en docs.flutter.dev.'),
                ('Widget of the Week', 'Un widget por video, en el canal de Flutter en YouTube.'),
                ('pub.dev', 'Para no reinventar la rueda.'),
              ],
            ),
          ),
          const SizedBox(width: 56),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const QrCode(data: start, size: 300),
              const SizedBox(height: 18),
              Text(
                'docs.flutter.dev/get-started',
                style: DeckType.mono.copyWith(color: colors.accentText),
              ),
              const SizedBox(height: 36),
              Text('Y la comunidad de aquí:', style: DeckType.small.copyWith(color: colors.muted)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final group in Config.organizers.where(
                    (name) => const {'BAQ JUG', 'CaribeDev', 'DevJVM'}.contains(name),
                  ))
                    Tag(group),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
