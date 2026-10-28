import 'package:material_ui/material_ui.dart';

import '../engine/slide.dart';
import '../live/join_card.dart';
import '../live/live_models.dart';
import '../live/poll_view.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/blocks.dart';
import '../ui/reveal.dart';
import '../ui/slide_scaffold.dart';
import '../ui/terminal.dart';
import 'sections.dart';

typedef _Scenario = ({String text, String answer, String reason});

const _scenarios = <_Scenario>[
  (
    text: 'Una startup necesita su app en iOS y Android ya, con un equipo pequeño.',
    answer: 'si',
    reason: 'Un código, un equipo, dos tiendas. Es el caso de libro.',
  ),
  (
    text: 'Una app con identidad visual propia y animaciones hechas a medida.',
    answer: 'si',
    reason: 'Flutter pinta cada píxel: tu diseño se ve igual en todas partes.',
  ),
  (
    text: 'Un blog o una tienda que vive de aparecer en Google.',
    answer: 'no',
    reason: 'Para SEO y contenido gana la web de siempre. Flutter web brilla en apps.',
  ),
  (
    text: 'Un juego 3D con gráficos de consola.',
    answer: 'no',
    reason: 'Unity o Unreal. Para juegos 2D casuales, Flame sobre Flutter sí.',
  ),
  (
    text: 'Una app que necesita lo último de iOS el mismo día que sale.',
    answer: 'depende',
    reason: 'Se puede, con código nativo y canales de plataforma. Ese día trabajas doble.',
  ),
  (
    text: 'La pantalla del tablero de un carro o la de un televisor.',
    answer: 'si',
    reason: 'Toyota y LG ya lo hacen con Flutter embebido.',
  ),
];

PollSpec _scenarioPoll(int index) => PollSpec(
  id: 'escenario-${index + 1}',
  question: _scenarios[index].text,
  options: [
    for (final (id, label) in const [
      ('si', 'Sí'),
      ('depende', 'Depende'),
      ('no', 'No'),
    ])
      PollOption(id, label, correct: id == _scenarios[index].answer),
  ],
);

const uncomfortablePoll = PollSpec(
  id: 'google-lo-mata',
  question: '¿Google va a matar a Flutter?',
  options: [
    PollOption('si', 'Sí, como a Google Reader'),
    PollOption('no', 'No'),
    PollOption('ya', 'Ya lo mató y no nos avisó'),
  ],
);

final analyzeSlides = [
  Slide(
    id: 'si-depende-no',
    section: analyzeSection,
    title: '¿Sí, depende o no?',
    steps: _scenarios.length * 2,
    cue: (step) => AudienceCue.poll(
      _scenarioPoll(step ~/ 2),
      open: step.isEven,
      revealed: step.isOdd,
    ),
    builder: (context, step) => _Scenarios(step: step),
  ),
  Slide(
    id: 'issues-found',
    section: analyzeSection,
    title: '3 issues found',
    steps: 2,
    builder: (context, step) => _IssuesFound(step: step),
  ),
  Slide(
    id: 'pregunta-incomoda',
    section: analyzeSection,
    title: 'La pregunta incómoda',
    steps: 2,
    skippable: true,
    cue: (step) => AudienceCue.poll(
      uncomfortablePoll,
      open: step == 0,
      revealed: step >= 1,
    ),
    builder: (context, step) => _Uncomfortable(step: step),
  ),
];

class _Scenarios extends StatelessWidget {
  const _Scenarios({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final index = step ~/ 2;
    final revealed = step.isOdd;
    final scenario = _scenarios[index];
    final answer = switch (scenario.answer) {
      'si' => ('Sí', colors.success),
      'no' => ('No', colors.danger),
      _ => ('Depende', const Color(0xFFFFC14D)),
    };
    return SlideScaffold(
      title: '¿Flutter sí, depende o no?',
      trailing: const JoinCard(qrSize: 170, compact: true),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escenario ${index + 1} de ${_scenarios.length}',
                  style: DeckType.monoLabel.copyWith(color: colors.accentText),
                ),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: Motion.base,
                  child: Text(
                    scenario.text,
                    key: ValueKey(index),
                    style: DeckType.title.copyWith(fontSize: 58, color: colors.ink),
                  ),
                ),
                const SizedBox(height: 40),
                Reveal(
                  visible: revealed,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                        decoration: BoxDecoration(
                          color: answer.$2.withValues(alpha: 0.16),
                          border: Border.all(color: answer.$2, width: 2),
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: Text(
                          answer.$1,
                          style: DeckType.headline.copyWith(color: answer.$2),
                        ),
                      ),
                      const SizedBox(width: 26),
                      Expanded(
                        child: Text(
                          scenario.reason,
                          style: DeckType.body.copyWith(color: colors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 72),
          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(top: 54),
              child: PollView(
                key: ValueKey(index),
                poll: _scenarioPoll(index),
                revealed: revealed,
                barHeight: 92,
                gap: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _analyzeLines = [
  TermLine.command('flutter analyze tu_proximo_proyecto'),
  TermLine('Analyzing tu_proximo_proyecto...', pause: Duration(milliseconds: 600)),
  TermLine(''),
  TermLine('   info • App para iOS y Android con un solo equipo • usa Flutter', tone: TermTone.success),
  TermLine('   info • Diseño propio y animaciones a medida      • usa Flutter', tone: TermTone.success),
  TermLine('   info • Paneles y herramientas internas en web    • usa Flutter', tone: TermTone.success),
  TermLine('warning • Lo último de cada plataforma el día uno  • depende', tone: TermTone.warning),
  TermLine('  error • Sitios que viven del SEO                 • web clásica', tone: TermTone.danger),
  TermLine('  error • Juegos 3D pesados                        • Unity o Unreal', tone: TermTone.danger),
  TermLine(''),
  TermLine('3 issues found. (ran in 0.4s)'),
];

class _IssuesFound extends StatelessWidget {
  const _IssuesFound({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'El resumen honesto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Terminal(lines: _analyzeLines, title: 'zsh · decisiones', fontSize: 23),
          const SizedBox(height: 40),
          Reveal(
            visible: step >= 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: colors.accentText, size: 40),
                const SizedBox(width: 20),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Dato honesto: la página que tienen en el celular '),
                        TextSpan(
                          text: 'no es Flutter.',
                          style: TextStyle(color: colors.accentText),
                        ),
                        const TextSpan(
                          text: ' Para tres botones que deben cargar al instante, '
                              'HTML es mejor. Saber cuándo no usarlo también es saber Flutter.',
                        ),
                      ],
                    ),
                    style: DeckType.body.copyWith(color: colors.muted),
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

class _Uncomfortable extends StatelessWidget {
  const _Uncomfortable({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final facts = [
      ('Google la usa en sus propias apps', 'Google Pay, NotebookLM, Google Earth, Classroom, YouTube Create…'),
      ('Es código abierto', 'Licencia BSD: el código se queda con la comunidad, pase lo que pase.'),
      ('Otros construyen productos encima', 'Canonical (Ubuntu), Toyota, LG.'),
      ('Sale una versión estable cada trimestre', 'La 3.47 salió el 12 de agosto de 2026.'),
      ('81.705 paquetes en pub.dev', 'Y contando.'),
    ];
    return SlideScaffold(
      title: 'La pregunta incómoda',
      lead: '¿Google va a matar a Flutter?',
      trailing: step == 0 ? const JoinCard(qrSize: 170, compact: true) : null,
      child: AnimatedSwitcher(
        duration: Motion.base,
        child: step == 0
            ? const SizedBox(
                key: ValueKey('votar'),
                width: 1100,
                child: PollView(poll: uncomfortablePoll, barHeight: 92, gap: 20),
              )
            : PointList(
                key: const ValueKey('datos'),
                points: facts,
                gap: 18,
                style: DeckType.headline.copyWith(fontSize: 34),
              ),
      ),
    );
  }
}
