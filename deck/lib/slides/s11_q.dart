import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../engine/deck_scope.dart';
import '../engine/slide.dart';
import '../live/join_card.dart';
import '../live/live_models.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/flutter_lockup.dart';
import '../ui/reveal.dart';
import '../ui/slide_scaffold.dart';
import '../ui/terminal.dart';
import 'sections.dart';

final quitSlides = [
  Slide(
    id: 'calificacion',
    section: quitSection,
    title: 'La calificación',
    cue: (step) => const AudienceCue.rating(),
    builder: (context, step) => const _Rating(),
  ),
  Slide(
    id: 'application-finished',
    section: quitSection,
    title: 'Application finished.',
    chrome: false,
    builder: (context, step) => const _Finished(),
  ),
];

const _captions = [
  'Segmentation fault',
  'Compila con warnings',
  'Funciona en mi máquina',
  'Pasa los tests',
  'Deploy un viernes y nada se rompió',
];

class _Rating extends StatelessWidget {
  const _Rating();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    return SlideScaffold(
      title: '¿Cómo estuvo? Califiquen el deploy',
      trailing: const JoinCard(qrSize: 170, compact: true),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: live,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: live.rating),
                    duration: Motion.slow,
                    builder: (context, value, _) => Text(
                      live.ratings == 0 ? '–' : value.toStringAsFixed(1),
                      style: DeckType.hero.copyWith(
                        fontSize: 220,
                        color: colors.ink,
                        fontFeatures: DeckType.tabular,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var star = 1; star <= 5; star++)
                        Icon(
                          star <= live.rating.round() ? Icons.star : Icons.star_border,
                          size: 64,
                          color: const Color(0xFFFFD25E),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '${live.ratings} calificaciones',
                    style: DeckType.mono.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 56),
          SizedBox(
            width: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, caption) in _captions.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: Row(
                            children: [
                              Text(
                                '${index + 1}',
                                style: DeckType.mono.copyWith(color: const Color(0xFFFFD25E)),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.star, size: 30, color: Color(0xFFFFD25E)),
                            ],
                          ),
                        ),
                        Text(caption, style: DeckType.small.copyWith(fontSize: 29, color: colors.ink)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _quitLines = [
  TermLine.command('q', pause: Duration(milliseconds: 500)),
  TermLine('Application finished.', pause: Duration(milliseconds: 500)),
];

class _Finished extends StatelessWidget {
  const _Finished();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.pageX, 110, Space.pageX, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 760,
            child: Terminal(lines: _quitLines, title: 'zsh · charla', fontSize: 26),
          ),
          const SizedBox(height: 64),
          EnterOnce(
            delay: const Duration(milliseconds: 1600),
            child: Text('Gracias.', style: DeckType.hero.copyWith(color: colors.ink)),
          ),
          const SizedBox(height: 18),
          EnterOnce(
            delay: const Duration(milliseconds: 1800),
            child: Text(
              '${Config.presenter} · ${Config.role}',
              style: DeckType.headline.copyWith(color: colors.muted),
            ),
          ),
          const Spacer(),
          EnterOnce(
            delay: const Duration(milliseconds: 2000),
            child: Text(
              'Gracias a ${Config.organizers.join(' · ')}',
              style: DeckType.small.copyWith(color: colors.faint),
            ),
          ),
          const SizedBox(height: 28),
          const Row(
            children: [
              FlutterLockup(height: 40),
              SizedBox(width: 36),
              Expanded(child: TrademarkNote()),
            ],
          ),
        ],
      ),
    );
  }
}
