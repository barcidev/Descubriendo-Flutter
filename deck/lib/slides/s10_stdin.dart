import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../engine/deck_scope.dart';
import '../engine/overview.dart';
import '../engine/slide.dart';
import '../live/join_card.dart';
import '../live/live_models.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/reveal.dart';
import '../ui/slide_scaffold.dart';
import 'sections.dart';

final stdinSlides = [
  Slide(
    id: 'preguntas',
    section: stdinSection,
    title: 'Preguntas',
    cue: (step) => const AudienceCue.questions(),
    builder: (context, step) => const _Questions(),
  ),
];

/// Lo mínimo que dura la espera, aunque la IA responda antes.
const _minimumWait = Duration(seconds: 10);

/// Las preguntas del público: el servidor las guarda toda la charla y, al
/// llegar aquí, una IA escoge cinco que cubran la mayoría de las dudas sin
/// repetirse. Mientras escoge, la charla «espera stdin».
class _Questions extends StatefulWidget {
  const _Questions();

  @override
  State<_Questions> createState() => _QuestionsState();
}

class _QuestionsState extends State<_Questions> {
  final _since = DateTime.now();
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    final thumbnail = Thumbnail.of(context);
    return SlideScaffold(
      title: 'stdin abierto: sus preguntas',
      lead: 'Una IA juntó las que se parecen y escogió cinco. Sin editarlas.',
      trailing: const JoinCard(qrSize: 170, compact: true),
      child: ListenableBuilder(
        listenable: live,
        builder: (context, _) {
          final round = live.questionRound;
          final waited = DateTime.now().difference(_since);
          // Si el servidor no contesta, a los 40 s se pasa a mano alzada.
          final gaveUp = waited > const Duration(seconds: 40);
          final ready = thumbnail ||
              gaveUp ||
              (round.phase == RoundPhase.ready && waited >= _minimumWait);
          final Widget body;
          if (!ready) {
            body = _Waiting(key: const ValueKey('esperando'), received: round.received);
          } else if (round.picks.isEmpty) {
            body = Center(
              key: const ValueKey('vacio'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'stdin vacío: 0 preguntas.',
                    style: DeckType.display.copyWith(fontFamily: DeckFonts.mono, color: colors.ink),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'O lo expliqué todo perfecto, o ya quieren ir a comer. '
                    '¿Alguien levanta la mano?',
                    style: DeckType.headline.copyWith(color: colors.muted),
                  ),
                ],
              ),
            );
          } else {
            body = Column(
              key: const ValueKey('preguntas'),
              children: [
                for (final (index, question) in round.picks.take(5).indexed)
                  EnterOnce(
                    delay: Duration(milliseconds: 200 + index * 450),
                    from: const Offset(0.05, 0),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(Radii.sm),
                        border: Border.all(color: colors.line, width: Space.hairline),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 74,
                            child: Text(
                              '${index + 1}',
                              style: DeckType.title.copyWith(
                                fontSize: 40,
                                color: colors.accentText,
                                fontFeatures: DeckType.tabular,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              question.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: DeckType.small.copyWith(fontSize: 30, color: colors.ink),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            asCall(question.author),
                            style: DeckType.monoSmall.copyWith(color: colors.faint),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }
          return AnimatedSwitcher(duration: Motion.slow, child: body);
        },
      ),
    );
  }
}

/// La espera: un FutureBuilder que no termina de cargar, signos de
/// pregunta que suben y lo que la IA va haciendo.
class _Waiting extends StatefulWidget {
  const _Waiting({required this.received, super.key});

  final int received;

  @override
  State<_Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<_Waiting> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Thumbnail.of(context) && !Motion.reduced(context) && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _steps => [
    widget.received == 0
        ? 'Esperando preguntas…'
        : 'Leyendo ${widget.received} ${widget.received == 1 ? 'pregunta' : 'preguntas'}…',
    'Juntando las que preguntan lo mismo…',
    'Descartando «¿hay refrigerio?»…',
    'Buscando la que me va a dejar callado…',
    'Escogiendo cinco…',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final elapsed = (_controller.lastElapsedDuration ?? Duration.zero).inMilliseconds;
        final stepIndex = (elapsed ~/ 2000) % _steps.length;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RisingMarks(t: _controller.value, color: colors.accent),
              ),
            ),
            Row(
              children: [
                SizedBox.square(
                  dimension: 360,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 300,
                        child: CircularProgressIndicator(
                          strokeWidth: 14,
                          color: Color.lerp(
                            colors.accent,
                            const Color(0xFFFFD25E),
                            (math.sin(_controller.value * 2 * math.pi) + 1) / 2,
                          ),
                          backgroundColor: colors.line,
                        ),
                      ),
                      Text(
                        '?',
                        style: DeckType.hero.copyWith(fontSize: 160, color: colors.ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 72),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FutureBuilder<List<Pregunta>>',
                        style: DeckType.mono.copyWith(fontSize: 34, color: colors.accentText),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'snapshot.connectionState == ConnectionState.waiting',
                        style: DeckType.mono.copyWith(fontSize: 26, color: colors.faint),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        height: 70,
                        child: AnimatedSwitcher(
                          duration: Motion.base,
                          child: Text(
                            _steps[stepIndex],
                            key: ValueKey(stepIndex),
                            style: DeckType.headline.copyWith(fontSize: 46, color: colors.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Signos de pregunta que suben despacio, cada uno con su vaivén.
class _RisingMarks extends CustomPainter {
  const _RisingMarks({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(5);
    for (var i = 0; i < 16; i++) {
      final x = random.nextDouble() * size.width;
      final speed = 0.6 + random.nextDouble() * 0.8;
      final phase = random.nextDouble();
      final fontSize = 28 + random.nextDouble() * 46;
      final progress = (t * speed + phase) % 1;
      final y = size.height * (1.1 - progress * 1.2);
      final sway = math.sin((progress + phase) * 2 * math.pi) * 24;
      final opacity = math.sin(progress * math.pi) * 0.35;
      final mark = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            fontFamily: DeckFonts.sans,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      mark.paint(canvas, Offset(x + sway, y));
    }
  }

  @override
  bool shouldRepaint(_RisingMarks oldDelegate) => oldDelegate.t != t || oldDelegate.color != color;
}
