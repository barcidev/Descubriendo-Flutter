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
import '../ui/slide_scaffold.dart';
import 'sections.dart';

/// Las diez preguntas del concurso: todo salió en la charla.
const quizBank = [
  QuizQuestion('¿Quién dibuja cada píxel de una app de Flutter?', [
    'Los componentes del sistema',
    'Su propio motor: Impeller',
    'El navegador',
    'Un pasante muy rápido',
  ], 1),
  QuizQuestion('En Flutter, ¿qué es un widget?', [
    'Solo los botones',
    'Una librería de JavaScript',
    'Todo: hasta el Padding',
    'Un plugin de Android Studio',
  ], 2),
  QuizQuestion('¿En qué lenguaje se programa con Flutter?', ['Dart', 'Kotlin', 'Swift', 'JavaScript'], 0),
  QuizQuestion('Con hot reload, al cambiar el color del contador, ¿qué pasa con el número?', [
    'Vuelve a cero',
    'Se duplica',
    'La app se cierra',
    'Se conserva',
  ], 3),
  QuizQuestion('UI = f( ? )', ['café', 'estado', 'CSS', 'pasante'], 1),
  QuizQuestion('En Dart, ¿qué significa String? (con el signo de pregunta)?', [
    'Que el texto puede ser null',
    'Que es un texto en duda',
    'Que es un error de compilación',
    'Que le pregunta algo al usuario',
  ], 0),
  QuizQuestion('¿Cuál de estas apps está hecha con Flutter?', ['WhatsApp', 'Instagram', 'Uber', 'Google Pay'], 3),
  QuizQuestion('Para un blog que vive de aparecer en Google, Flutter es…', [
    'La mejor opción',
    'Mejor la web de siempre',
    'Obligatorio',
    'Lo que diga el pasante',
  ], 1),
  QuizQuestion('¿Dónde se buscan los paquetes de Flutter?', ['npm', 'Maven Central', 'pub.dev', 'La App Store'], 2),
  QuizQuestion('¿Qué comando crea un proyecto nuevo de Flutter?', [
    'flutter new',
    'flutter init',
    'npm create flutter',
    'flutter create',
  ], 3),
];

/// Intro, y por cada pregunta dos pasos (la pregunta y la tabla), y el podio.
const _contestSteps = 2 + 2 * 10;

final contestSlide = Slide(
  id: 'concurso',
  section: quitSection,
  title: 'El concurso',
  steps: _contestSteps,
  cue: (step) => switch (_stage(step)) {
    (_Stage.intro, _) => const AudienceCue.quiz('intro'),
    (_Stage.question, final index) => AudienceCue.quiz('pregunta', index: index),
    (_Stage.board, final index) => AudienceCue.quiz('tabla', index: index),
    (_Stage.podium, _) => const AudienceCue.quiz('podio'),
  },
  builder: (context, step) => _Contest(step: step),
);

enum _Stage { intro, question, board, podium }

(_Stage, int) _stage(int step) {
  if (step == 0) return (_Stage.intro, -1);
  if (step >= _contestSteps - 1) return (_Stage.podium, -1);
  return step.isOdd ? (_Stage.question, (step - 1) ~/ 2) : (_Stage.board, (step - 2) ~/ 2);
}

// Los colores y las figuras de siempre: triángulo, rombo, círculo y cuadrado.
const _tileColors = [Color(0xFFE21B3C), Color(0xFF1368CE), Color(0xFFD89E00), Color(0xFF26890C)];

/// El concurso tipo Kahoot del final: el servidor abre cada pregunta 30 s,
/// lleva los puntos (acertar rápido vale más) y la charla muestra la tabla
/// animada después de cada una y el podio al final.
class _Contest extends StatefulWidget {
  const _Contest({required this.step});

  final int step;

  @override
  State<_Contest> createState() => _ContestState();
}

class _ContestState extends State<_Contest> {
  QuizPhase? _lastPhase;
  int? _lastIndex;

  /// Si la pregunta se cierra sola (tiempo o todos respondieron), la charla
  /// pasa sola a la tabla: el siguiente clic ya es la otra pregunta.
  void _follow(QuizState quiz) {
    final (stage, index) = _stage(widget.step);
    final closed = _lastPhase == QuizPhase.question &&
        _lastIndex == index &&
        quiz.index == index &&
        quiz.phase == QuizPhase.board;
    _lastPhase = quiz.phase;
    _lastIndex = quiz.index;
    if (stage != _Stage.question || !closed) return;
    final deck = DeckScope.of(context).deck;
    final step = widget.step;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (deck.slide.id == 'concurso' && deck.step == step) deck.next();
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = DeckScope.of(context).live;
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) {
        final quiz = live.quiz;
        _follow(quiz);
        final (stage, index) = _stage(widget.step);
        return AnimatedSwitcher(
          duration: Motion.base,
          child: switch (stage) {
            _Stage.intro => _ContestIntro(key: const ValueKey('intro'), players: math.max(quiz.players, live.people)),
            _Stage.question => _ContestQuestion(key: ValueKey('p$index'), index: index, quiz: quiz),
            _Stage.board => _ContestBoard(key: ValueKey('t$index'), index: index, quiz: quiz),
            _Stage.podium => _ContestPodium(key: const ValueKey('podio'), board: quiz.board),
          },
        );
      },
    );
  }
}

/// Una figura de las cuatro, para las opciones y las reglas.
class _Shape extends StatelessWidget {
  const _Shape(this.kind, {this.size = 44});

  final int kind;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _ShapePainter(kind, const Color(0xFFFFFFFF)));
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter(this.kind, this.color);

  final int kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    switch (kind % 4) {
      case 0:
        canvas.drawPath(Path()..moveTo(w / 2, h * 0.08)..lineTo(w * 0.95, h * 0.88)..lineTo(w * 0.05, h * 0.88)..close(), paint);
      case 1:
        canvas.drawPath(Path()..moveTo(w / 2, 0)..lineTo(w, h / 2)..lineTo(w / 2, h)..lineTo(0, h / 2)..close(), paint);
      case 2:
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.46, paint);
      default:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.84), Radius.circular(w * 0.08)),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_ShapePainter oldDelegate) => oldDelegate.kind != kind || oldDelegate.color != color;
}

/// Antes de empezar: las reglas y el botón de comenzar.
class _ContestIntro extends StatelessWidget {
  const _ContestIntro({required this.players, super.key});

  final int players;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final deck = DeckScope.of(context).deck;
    const rules = [
      '30 segundos por pregunta. Se responde en el celular.',
      'Si aciertas, hasta 1000 puntos: entre más rápido, más.',
      'Si fallas, 0. Nadie se entera… salvo la tabla.',
      'Al final, podio para los tres primeros.',
    ];
    return SlideScaffold(
      title: 'Concurso final: ¿quién estuvo pilas?',
      lead: '10 preguntas sobre todo lo que vimos hoy.',
      trailing: const JoinCard(qrSize: 170, compact: true),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, rule) in rules.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 26),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _tileColors[index],
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          alignment: Alignment.center,
                          child: _Shape(index, size: 34),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          child: Text(rule, style: DeckType.headline.copyWith(fontSize: 38, color: colors.ink)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                ExcludeFocus(
                  child: FilledButton.icon(
                    onPressed: deck.next,
                    icon: const Icon(Icons.play_arrow_rounded, size: 44),
                    label: const Text('Comenzar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.fromLTRB(36, 22, 48, 22),
                      textStyle: DeckType.headline.copyWith(fontSize: 40, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 64),
          SizedBox(
            width: 380,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: players.toDouble()),
                  duration: Motion.slow,
                  builder: (context, value, _) => Text(
                    '${value.round()}',
                    style: DeckType.hero.copyWith(fontSize: 200, color: colors.ink, fontFeatures: DeckType.tabular),
                  ),
                ),
                Text(
                  players == 1 ? 'jugador listo' : 'jugadores listos',
                  style: DeckType.headline.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Una pregunta abierta: el reloj, cuántos respondieron y las cuatro opciones.
class _ContestQuestion extends StatefulWidget {
  const _ContestQuestion({required this.index, required this.quiz, super.key});

  final int index;
  final QuizState quiz;

  @override
  State<_ContestQuestion> createState() => _ContestQuestionState();
}

class _ContestQuestionState extends State<_ContestQuestion> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(milliseconds: 250), (_) {
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
    final question = quizBank[widget.index];
    final quiz = widget.quiz;
    final live = quiz.index == widget.index;
    final open = live && quiz.phase == QuizPhase.question;
    final seconds = open ? (quiz.remaining(DateTime.now()).inMilliseconds / 1000).ceil() : (live ? 0 : 30);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.pageX, 60, Space.pageX, Space.pageBottom - 20),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Pregunta ${widget.index + 1} de ${quizBank.length}',
                style: DeckType.monoLabel.copyWith(fontSize: 26, color: colors.accentText),
              ),
              const Spacer(),
              Text(
                '${live ? quiz.answered : 0} de ${quiz.players} respondieron',
                style: DeckType.mono.copyWith(color: colors.muted, fontFeatures: DeckType.tabular),
              ),
              const SizedBox(width: 36),
              SizedBox.square(
                dimension: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 120,
                      child: CircularProgressIndicator(
                        value: seconds / 30,
                        strokeWidth: 10,
                        color: seconds <= 5 ? const Color(0xFFFFD25E) : colors.accent,
                        backgroundColor: colors.line,
                      ),
                    ),
                    Text(
                      '$seconds',
                      style: DeckType.title.copyWith(fontSize: 52, color: colors.ink, fontFeatures: DeckType.tabular),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: Text(
                question.text,
                textAlign: TextAlign.center,
                style: DeckType.display.copyWith(fontSize: 76, color: colors.ink),
              ),
            ),
          ),
          _Tiles(question: question),
        ],
      ),
    );
  }
}

/// Las cuatro opciones en sus colores. Con [counts], ya cerrada: la correcta
/// resalta y cada una dice cuántos la escogieron.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.question, this.counts});

  static const height = 150.0;

  final QuizQuestion question;
  final List<int>? counts;

  @override
  Widget build(BuildContext context) {
    final revealed = counts != null;
    Widget tile(int option) {
      final correct = option == question.correct;
      return Expanded(
        child: AnimatedOpacity(
          duration: Motion.slow,
          opacity: revealed && !correct ? 0.28 : 1,
          child: Container(
            height: height,
            margin: const EdgeInsets.all(9),
            padding: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: _tileColors[option],
              borderRadius: BorderRadius.circular(Radii.sm),
              border: revealed && correct ? Border.all(color: const Color(0xFFFFFFFF), width: 5) : null,
              boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 6))],
            ),
            child: Row(
              children: [
                _Shape(option),
                const SizedBox(width: 26),
                Expanded(
                  child: Text(
                    question.options[option],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DeckType.headline.copyWith(fontSize: 38, color: const Color(0xFFFFFFFF)),
                  ),
                ),
                if (revealed) ...[
                  if (correct) const Icon(Icons.check_circle, color: Color(0xFFFFFFFF), size: 46),
                  const SizedBox(width: 14),
                  Text(
                    option < counts!.length ? '${counts![option]}' : '0',
                    style: DeckType.title.copyWith(fontSize: 46, color: const Color(0xFFFFFFFF), fontFeatures: DeckType.tabular),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [tile(0), tile(1)]),
        if (question.options.length > 2) Row(children: [tile(2), if (question.options.length > 3) tile(3)]),
      ],
    );
  }
}

/// Después de cada pregunta: primero la respuesta y cuántos escogieron cada
/// opción; después la tabla, que se reacomoda con los puntos nuevos.
class _ContestBoard extends StatefulWidget {
  const _ContestBoard({required this.index, required this.quiz, super.key});

  final int index;
  final QuizState quiz;

  @override
  State<_ContestBoard> createState() => _ContestBoardState();
}

class _ContestBoardState extends State<_ContestBoard> {
  bool _showBoard = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Thumbnail.of(context) || Motion.reduced(context)) {
      _showBoard = true;
    } else {
      _timer ??= Timer(const Duration(milliseconds: 3800), () {
        if (mounted) setState(() => _showBoard = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final question = quizBank[widget.index];
    final quiz = widget.quiz;
    final counts = quiz.index == widget.index ? quiz.distribution : const <int>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.pageX, 60, Space.pageX, Space.pageBottom - 20),
      child: AnimatedSwitcher(
        duration: Motion.slow,
        child: !_showBoard
            ? Column(
                key: const ValueKey('respuesta'),
                children: [
                  Text(
                    'Pregunta ${widget.index + 1} de ${quizBank.length}',
                    style: DeckType.monoLabel.copyWith(fontSize: 26, color: colors.accentText),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        question.text,
                        textAlign: TextAlign.center,
                        style: DeckType.display.copyWith(fontSize: 64, color: colors.ink),
                      ),
                    ),
                  ),
                  _Tiles(question: question, counts: counts.isEmpty ? List.filled(question.options.length, 0) : counts),
                ],
              )
            : Column(
                key: const ValueKey('tabla'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Después de la pregunta ${widget.index + 1} de ${quizBank.length}',
                    style: DeckType.monoLabel.copyWith(fontSize: 26, color: colors.accentText),
                  ),
                  const SizedBox(height: 10),
                  Text('Tabla de posiciones', style: DeckType.title.copyWith(color: colors.ink)),
                  const SizedBox(height: 28),
                  Expanded(child: _Leaderboard(rows: quiz.board)),
                ],
              ),
      ),
    );
  }
}

/// La tabla: cada fila arranca en su puesto anterior y sube (o baja) al
/// nuevo, mientras los puntos cuentan hasta el total.
class _Leaderboard extends StatefulWidget {
  const _Leaderboard({required this.rows});

  final List<QuizRow> rows;

  @override
  State<_Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<_Leaderboard> {
  bool _settled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Thumbnail.of(context) || Motion.reduced(context)) {
      _settled = true;
    } else if (!_settled) {
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _settled = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (widget.rows.isEmpty) {
      return Center(
        child: Text(
          'Nadie ha jugado todavía. ¿Están ahí?',
          style: DeckType.headline.copyWith(color: colors.muted),
        ),
      );
    }
    const rowHeight = 72.0;
    const gap = 10.0;
    const medals = [Color(0xFFFFD25E), Color(0xFFC9D6EA), Color(0xFFE0A070)];
    return Stack(
      children: [
        for (final row in widget.rows)
          AnimatedPositioned(
            key: ValueKey(row.name + row.widget),
            duration: const Duration(milliseconds: 1300),
            curve: Motion.emphasized,
            left: 0,
            right: 0,
            top: ((_settled ? row.rank : math.min(row.rankBefore, 9)) - 1) * (rowHeight + gap),
            height: rowHeight,
            child: AnimatedOpacity(
              duration: Motion.slow,
              opacity: _settled || row.rankBefore <= 8 ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border: Border(
                    left: BorderSide(
                      color: row.rank <= 3 ? medals[row.rank - 1] : colors.line,
                      width: 6,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${row.rank}',
                        style: DeckType.title.copyWith(
                          fontSize: 40,
                          color: row.rank <= 3 ? medals[row.rank - 1] : colors.muted,
                          fontFeatures: DeckType.tabular,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: row.name),
                            TextSpan(
                              text: '   ${asCall(row.widget)}',
                              style: DeckType.monoSmall.copyWith(color: colors.faint),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DeckType.headline.copyWith(fontSize: 34, color: colors.ink),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: Motion.base,
                      opacity: _settled && row.gained > 0 ? 1 : 0,
                      child: Container(
                        margin: const EdgeInsets.only(right: 22),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.success.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: Text(
                          '+${row.gained}',
                          style: DeckType.mono.copyWith(color: colors.success, fontFeatures: DeckType.tabular),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: row.before.toDouble(), end: (_settled ? row.points : row.before).toDouble()),
                        duration: const Duration(milliseconds: 1300),
                        curve: Motion.emphasized,
                        builder: (context, value, _) => Text(
                          _thousands(value.round()),
                          textAlign: TextAlign.right,
                          style: DeckType.title.copyWith(fontSize: 40, color: colors.ink, fontFeatures: DeckType.tabular),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _thousands(int value) {
  final digits = '$value';
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// El podio: suben el tercero, el segundo y, después de un redoble, el
/// ganador, con trofeo y confeti.
class _ContestPodium extends StatefulWidget {
  const _ContestPodium({required this.board, super.key});

  final List<QuizRow> board;

  @override
  State<_ContestPodium> createState() => _ContestPodiumState();
}

class _ContestPodiumState extends State<_ContestPodium> with TickerProviderStateMixin {
  late final _rise = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000));
  late final _confetti = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Thumbnail.of(context) || Motion.reduced(context)) {
      _rise.value = 1;
    } else if (!_rise.isAnimating && _rise.value == 0) {
      _rise.forward();
      _rise.addListener(() {
        if (_rise.value > 0.72 && !_confetti.isAnimating) _confetti.repeat();
      });
    }
  }

  @override
  void dispose() {
    _rise.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final top = widget.board.take(3).toList();
    if (top.isEmpty) {
      return Center(
        child: Text(
          'Nadie jugó… ¿estaban dormidos?',
          style: DeckType.display.copyWith(color: colors.muted),
        ),
      );
    }
    // En el podio: el segundo a la izquierda, el primero al centro y el
    // tercero a la derecha.
    const heights = [440.0, 320.0, 240.0];
    const medals = [Color(0xFFFFD25E), Color(0xFFC9D6EA), Color(0xFFE0A070)];
    const windows = [(0.55, 0.72), (0.22, 0.38), (0.04, 0.2)];
    final order = [if (top.length > 1) 1, 0, if (top.length > 2) 2];
    return AnimatedBuilder(
      animation: Listenable.merge([_rise, _confetti]),
      builder: (context, _) {
        final winnerShown = _rise.value >= windows[0].$2;
        return Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.pageX, 70, Space.pageX, 0),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: Motion.slow,
                    child: Text(
                      winnerShown ? '¡${top.first.name} estuvo más pilas que nadie!' : '¿Y quién estuvo más pilas?',
                      key: ValueKey(winnerShown),
                      textAlign: TextAlign.center,
                      style: DeckType.display.copyWith(color: winnerShown ? medals[0] : colors.ink),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final place in order)
                        Builder(
                          builder: (context) {
                            final (start, end) = windows[place];
                            final t = Curves.easeOutBack.transform(((_rise.value - start) / (end - start)).clamp(0.0, 1.0));
                            final row = top[place];
                            final winner = place == 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: SizedBox(
                                width: 400,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Opacity(
                                      opacity: t.clamp(0.0, 1.0),
                                      child: Column(
                                        children: [
                                          if (winner)
                                            const Icon(Icons.emoji_events, color: Color(0xFFFFD25E), size: 110),
                                          Text(
                                            row.name,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: DeckType.title.copyWith(fontSize: winner ? 60 : 44, color: colors.ink),
                                          ),
                                          Text(
                                            asCall(row.widget),
                                            style: DeckType.mono.copyWith(color: colors.accentText),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${_thousands(row.points)} puntos',
                                            style: DeckType.mono.copyWith(color: colors.muted, fontFeatures: DeckType.tabular),
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: heights[place] * t.clamp(0.0, 1.2),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [medals[place], medals[place].withValues(alpha: 0.35)],
                                        ),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.md)),
                                        boxShadow: winner && winnerShown
                                            ? [BoxShadow(color: medals[0].withValues(alpha: 0.45), blurRadius: 60)]
                                            : null,
                                      ),
                                      alignment: Alignment.topCenter,
                                      padding: const EdgeInsets.only(top: 18),
                                      child: Text(
                                        '${place + 1}',
                                        style: DeckType.hero.copyWith(fontSize: 120, color: colors.canvas),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (winnerShown)
              IgnorePointer(child: CustomPaint(painter: _ConfettiPainter(_confetti.value))),
          ],
        );
      },
    );
  }
}

/// Confeti que cae sin parar, con los colores del concurso y de Flutter.
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(3);
    const palette = [..._tileColors, Color(0xFFFFD25E), FlutterBrand.sky, Color(0xFFFFFFFF)];
    for (var i = 0; i < 110; i++) {
      final x = random.nextDouble() * size.width;
      final speed = 0.6 + random.nextDouble() * 0.9;
      final phase = random.nextDouble();
      final progress = (t * speed + phase) % 1;
      final y = -40 + progress * (size.height + 80);
      final sway = math.sin((progress * 4 + phase) * math.pi) * 30;
      final angle = (progress * 8 + phase * 6) * math.pi;
      canvas
        ..save()
        ..translate(x + sway, y)
        ..rotate(angle)
        ..drawRect(
          const Rect.fromLTWH(-7, -4, 14, 8),
          Paint()..color = palette[i % palette.length],
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
