import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../demos/excusometro.dart';
import '../demos/ruleta.dart';
import '../demos/tarjeta.dart' as tarjeta;
import '../engine/deck_scope.dart';
import '../engine/slide.dart';
import '../live/join_card.dart';
import '../live/live_models.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/blocks.dart';
import '../ui/code_block.dart';
import '../ui/guide_box.dart';
import '../ui/highlighter.dart';
import '../ui/reveal.dart';
import '../ui/slide_scaffold.dart';
import '../ui/terminal.dart';
import 'sections.dart';

final buildSlides = [
  Slide(
    id: 'todo-es-un-widget',
    section: buildSection,
    title: 'Todo es un widget',
    builder: (context, step) => const _EverythingIsAWidget(),
  ),
  Slide(
    id: 'armemos-una-tarjeta',
    section: buildSection,
    title: 'Armemos una tarjeta',
    steps: _cardSteps.length,
    builder: (context, step) => _CardComposer(step: step),
  ),
  Slide(
    id: 'ui-estado',
    section: buildSection,
    title: 'UI = f(estado)',
    steps: 2,
    builder: (context, step) => _UiIsAFunction(step: step),
  ),
  Slide(
    id: 'excusometro-en-vivo',
    section: buildSection,
    title: 'Excusómetro en vivo',
    steps: 2,
    // Un minuto para escribir. Pasar de paso cierra la ronda antes.
    cue: (step) => AudienceCue.excuse(open: step == 0, seconds: excuseSeconds),
    builder: (context, step) => _LiveExcuses(step: step),
  ),
  Slide(
    id: 'contador',
    section: buildSection,
    title: 'El contador más grande del mundo',
    cue: (step) => const AudienceCue.counter(),
    builder: (context, step) => const _BiggestCounter(),
  ),
  Slide(
    id: 'hot-reload',
    section: buildSection,
    title: 'Hot reload en vivo',
    steps: 2,
    cue: (step) => const AudienceCue.counter(),
    builder: (context, step) => _HotReload(step: step),
  ),
  Slide(
    id: 'por-que-tan-rapido',
    section: buildSection,
    title: '¿Por qué tan rápido?',
    builder: (context, step) => const _WhyFast(),
  ),
];

const _tree = '''
Card
└── Padding
    └── Column
        ├── Row
        │   ├── Icon
        │   └── Text        'Excusómetro'
        ├── Text            excusa
        ├── Text            '— Todo dev, alguna vez'
        └── FilledButton
            └── Text        'Otra excusa'
''';

class _EverythingIsAWidget extends StatelessWidget {
  const _EverythingIsAWidget();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'Todo es un widget',
      lead: 'Sí, todo. Sobre todo el padding.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(36, 30, 36, 30),
              decoration: BoxDecoration(
                color: CodeColors.background,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: CodeColors.border, width: Space.hairline),
              ),
              child: Text(
                _tree.trim(),
                style: DeckType.code.copyWith(fontSize: 27, color: CodeColors.type),
              ),
            ),
          ),
          const SizedBox(width: 64),
          SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Theme(
                  data: demoTheme(colors.brightness),
                  child: const GuideBox(
                    label: 'Card',
                    child: ExcuseCard(
                      excuse: 'Funciona en mi máquina.',
                      onAnother: _noop,
                    ),
                  ),
                ),
                const SizedBox(height: 56),
                Text(
                  'Texto, botones, márgenes, centrado, animaciones, temas: '
                  'todo se arma igual, poniendo unos widgets dentro de otros.',
                  style: DeckType.small.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}

const _counterDart = '''
class _ContadorState extends State<Contador> {
  int _contador = 0;

  void _sumar() {
    setState(() {
      _contador++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text('\$_contador');
  }
}''';

const _counterKotlin = '''
@Composable
fun Contador() {
    var contador by remember { mutableIntStateOf(0) }
    Text("\$contador", Modifier.clickable { contador++ })
}''';

class _UiIsAFunction extends StatelessWidget {
  const _UiIsAFunction({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  'UI = f(estado)',
                  style: DeckType.hero.copyWith(
                    fontFamily: DeckFonts.mono,
                    fontSize: 112,
                    letterSpacing: -2,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'No le dices a la pantalla qué cambiar. Cambias el estado '
                  'y Flutter vuelve a construir lo que depende de él.',
                  style: DeckType.headline.copyWith(fontSize: 38, color: colors.muted),
                ),
                const SizedBox(height: 32),
                Reveal(
                  visible: step >= 1,
                  child: Text(
                    'Si vienes de Jetpack Compose, esto ya lo conoces.',
                    style: DeckType.headline.copyWith(fontSize: 38, color: colors.accentText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 56),
          Expanded(
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CodeBlock(
                  code: _counterDart,
                  fileName: 'contador.dart',
                  fontSize: 20,
                  focus: {5, 6, 7},
                ),
                const SizedBox(height: 20),
                Reveal(
                  visible: step >= 1,
                  child: const CodeBlock(
                    code: _counterKotlin,
                    language: CodeLang.kotlin,
                    fileName: 'Contador.kt',
                    fontSize: 20,
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

/// Cuánto dura la ronda de excusas.
const excuseSeconds = 60;

/// La ronda de excusas: un minuto para escribir (con la ruleta de la culpa
/// girando), la IA haciendo code review y las elegidas en pantalla.
class _LiveExcuses extends StatefulWidget {
  const _LiveExcuses({required this.step});

  final int step;

  @override
  State<_LiveExcuses> createState() => _LiveExcusesState();
}

class _LiveExcusesState extends State<_LiveExcuses> {
  Timer? _clock;

  /// Desde cuándo se ve el code review: se muestra al menos unos segundos,
  /// aunque la IA responda antes.
  DateTime? _reviewSince;
  RoundPhase? _lastPhase;

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

  /// Cuando se acaba el tiempo con la diapositiva en su primer paso, la
  /// charla pasa sola al segundo: el siguiente clic ya es otra diapositiva.
  void _follow(RoundPhase phase) {
    if (phase == _lastPhase) return;
    final before = _lastPhase;
    _lastPhase = phase;
    if (phase == RoundPhase.choosing || phase == RoundPhase.ready) {
      _reviewSince ??= DateTime.now();
    }
    if (before == RoundPhase.open && phase != RoundPhase.open && widget.step == 0) {
      final deck = DeckScope.of(context).deck;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (deck.slide.id == 'excusometro-en-vivo' && deck.step == 0) deck.next();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    return SlideScaffold(
      title: 'Mándame tu mejor excusa de dev',
      lead: 'Tienes un minuto. Después, una IA escoge las que salen en pantalla.',
      trailing: const JoinCard(qrSize: 170, compact: true),
      child: ListenableBuilder(
        listenable: live,
        builder: (context, _) {
          final round = live.excuseRound;
          _follow(round.phase);
          final now = DateTime.now();
          final reviewing = round.phase == RoundPhase.choosing ||
              (round.phase == RoundPhase.ready &&
                  now.difference(_reviewSince ?? now) < const Duration(milliseconds: 3200));
          final Widget body = switch (round.phase) {
            _ when reviewing => _Review(
              key: const ValueKey('review'),
              received: round.received,
            ),
            RoundPhase.ready => _ChosenExcuses(
              key: const ValueKey('ready'),
              picks: round.picks,
              received: round.received,
              byAi: round.byAi,
            ),
            _ => Row(
              key: const ValueKey('open'),
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _Countdown(
                    remaining: round.phase == RoundPhase.open
                        ? round.remaining(now)
                        : const Duration(seconds: excuseSeconds),
                    received: round.received,
                  ),
                ),
                const SizedBox(width: 48),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Mientras tanto, la ruleta de la culpa:',
                      style: DeckType.small.copyWith(color: colors.muted),
                    ),
                    const SizedBox(height: 18),
                    const BlameWheel(size: 470),
                  ],
                ),
              ],
            ),
          };
          return AnimatedSwitcher(duration: Motion.slow, child: body);
        },
      ),
    );
  }
}

/// El reloj grande: minutos y segundos, y un anillo que se vacía.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining, required this.received});

  final Duration remaining;
  final int received;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    final share = remaining.inMilliseconds / (excuseSeconds * 1000);
    final urgent = seconds <= 10;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox.square(
              dimension: 120,
              child: CustomPaint(
                painter: _RingPainter(
                  share: share.clamp(0, 1),
                  color: urgent ? const Color(0xFFFFD25E) : colors.accent,
                  track: colors.line,
                ),
              ),
            ),
            const SizedBox(width: 36),
            Text(
              '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
              style: DeckType.hero.copyWith(
                fontFamily: DeckFonts.mono,
                fontSize: 210,
                letterSpacing: -6,
                color: urgent ? const Color(0xFFFFD25E) : colors.ink,
                fontFeatures: DeckType.tabular,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$received',
                style: TextStyle(color: colors.accentText, fontFeatures: DeckType.tabular),
              ),
              TextSpan(text: received == 1 ? ' excusa en camino' : ' excusas en camino'),
            ],
          ),
          style: DeckType.headline.copyWith(fontSize: 44, color: colors.ink),
        ),
        const SizedBox(height: 14),
        Text(
          'Escríbela en el celular. Hasta tres por persona.',
          style: DeckType.small.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.share, required this.color, required this.track});

  final double share;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(8);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawArc(rect, 0, 2 * 3.14159265, false, stroke..color = track)
      ..drawArc(rect, -3.14159265 / 2, 2 * 3.14159265 * share, false, stroke..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.share != share || oldDelegate.color != color || oldDelegate.track != track;
}

/// Mientras la IA escoge: un code review de mentiras, línea por línea.
class _Review extends StatelessWidget {
  const _Review({required this.received, super.key});

  final int received;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Terminal(
            title: 'zsh · code review',
            fontSize: 26,
            minLines: 8,
            lines: [
              TermLine.command('gemini review --excusas ${received == 0 ? 'todas' : received}', pause: const Duration(milliseconds: 200)),
              const TermLine('› Leyendo cada excusa con calma…', tone: TermTone.muted, pause: Duration(milliseconds: 500)),
              const TermLine('› Juntando las que dicen lo mismo…', tone: TermTone.muted, pause: Duration(milliseconds: 550)),
              const TermLine('› Descartando «no sé» y «asdf»…', tone: TermTone.muted, pause: Duration(milliseconds: 550)),
              const TermLine('› Midiendo el sentido del humor…', tone: TermTone.muted, pause: Duration(milliseconds: 550)),
              const TermLine('› Buscando la más rara…', tone: TermTone.muted, pause: Duration(milliseconds: 550)),
              const TermLine('✓ Approved, with comments', tone: TermTone.success, pause: Duration(milliseconds: 600)),
            ],
          ),
        ),
        const SizedBox(width: 64),
        SizedBox(
          width: 520,
          child: Text(
            'Una IA está leyendo sus excusas. Si la suya no sale, no es personal: '
            'es el algoritmo.',
            style: DeckType.headline.copyWith(fontSize: 40, color: colors.muted),
          ),
        ),
      ],
    );
  }
}

/// Las excusas elegidas, sin categorías: entran una por una.
class _ChosenExcuses extends StatelessWidget {
  const _ChosenExcuses({
    required this.picks,
    required this.received,
    required this.byAi,
    super.key,
  });

  final List<AudienceText> picks;
  final int received;
  final bool byAi;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = math.max(received, picks.length);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 24.0;
        final width = (constraints.maxWidth - gap * 2) / 3;
        final height = (constraints.maxHeight - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (index, excuse) in picks.take(5).indexed)
              EnterOnce(
                delay: Duration(milliseconds: 250 + index * 420),
                child: Container(
                  width: width,
                  height: height,
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 26),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: colors.line, width: Space.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.format_quote, color: colors.accent, size: 44),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          excuse.text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: DeckType.headline.copyWith(fontSize: 34, color: colors.ink),
                        ),
                      ),
                      Text(
                        '— ${excuse.author}()',
                        style: DeckType.mono.copyWith(color: colors.accentText),
                      ),
                    ],
                  ),
                ),
              ),
            EnterOnce(
              delay: Duration(milliseconds: 250 + picks.length * 420),
              child: SizedBox(
                width: width,
                height: height,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        byAi
                            ? 'Elegidas por una IA entre $total excusas.'
                            : 'Elegidas entre $total excusas.',
                        style: DeckType.small.copyWith(color: colors.muted),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Llegó un dato, cambió el estado y Flutter repintó. '
                        'Nadie tocó estas tarjetas.',
                        style: DeckType.small.copyWith(color: colors.faint),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BiggestCounter extends StatelessWidget {
  const _BiggestCounter();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    return SlideScaffold(
      title: 'El contador más grande del mundo',
      lead: 'El de flutter create, pero lo aprietan ustedes.',
      trailing: const JoinCard(qrSize: 170, compact: true),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Han presionado el botón esta cantidad de veces:',
                  style: DeckType.headline.copyWith(fontSize: 36, color: colors.muted),
                ),
                ListenableBuilder(
                  listenable: live,
                  builder: (context, _) => TweenAnimationBuilder<double>(
                    tween: Tween(end: live.counter.toDouble()),
                    duration: Motion.base,
                    builder: (context, value, _) => Text(
                      value.round().toString(),
                      style: DeckType.hero.copyWith(
                        fontSize: 300,
                        letterSpacing: -10,
                        color: colors.ink,
                        fontFeatures: DeckType.tabular,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(
                width: 560,
                child: CodeBlock(
                  code: '''
void _sumar() {
  setState(() {
    _contador++;
  });
}''',
                  fileName: 'main.dart',
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 64),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _templateBefore = '''
theme: ThemeData(
  // TRY THIS: [...] try changing the seedColor in the colorScheme below
  // to Colors.green and then invoke "hot reload" [...]
  // Notice that the counter didn't reset back to zero; the application
  // state is not lost during the reload.
  colorScheme: .fromSeed(seedColor: Colors.deepPurple),
),
home: const MyHomePage(title: 'Flutter Demo Home Page'),''';

const _templateAfter = '''
theme: ThemeData(
  // TRY THIS: [...] try changing the seedColor in the colorScheme below
  // to Colors.green and then invoke "hot reload" [...]
  // Notice that the counter didn't reset back to zero; the application
  // state is not lost during the reload.
  colorScheme: .fromSeed(seedColor: Color(0xFF027DFD)),
),
home: const MyHomePage(title: 'Funciona en mi máquina'),''';

class _HotReload extends StatelessWidget {
  const _HotReload({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    return SlideScaffold(
      title: 'Hot reload, en vivo',
      lead: 'Ustedes sigan apretando. Yo cambio el código.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CodeBlock(
                  code: step == 0 ? _templateBefore : _templateAfter,
                  fileName: 'contador/lib/main.dart · la plantilla de flutter create',
                  fontSize: 20,
                  focus: const {6, 8},
                ),
                const SizedBox(height: 32),
                PointList(
                  visible: step + 2,
                  gap: 12,
                  style: DeckType.headline.copyWith(fontSize: 30),
                  points: const [
                    ('Cambio el color y el título, y guardo', null),
                    ('En menos de un segundo, la app cambia', null),
                    ('Y el número no vuelve a cero: el estado se conserva', null),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
          ListenableBuilder(
            listenable: live,
            builder: (context, _) => _CounterPhone(
              reloaded: step >= 1,
              count: live.counter,
              frame: colors.line,
            ),
          ),
        ],
      ),
    );
  }
}

/// La app de la plantilla, tal cual: AppBar con el color de la semilla, el
/// texto en inglés y el botón flotante. Al «guardar», cambia el tema y el
/// título, pero el número sigue donde iba.
class _CounterPhone extends StatefulWidget {
  const _CounterPhone({required this.reloaded, required this.count, required this.frame});

  final bool reloaded;
  final int count;
  final Color frame;

  @override
  State<_CounterPhone> createState() => _CounterPhoneState();
}

class _CounterPhoneState extends State<_CounterPhone> {
  /// Cuándo fue el último hot reload, para el aviso de la terminal.
  DateTime? _reloadedAt;

  @override
  void didUpdateWidget(_CounterPhone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reloaded != oldWidget.reloaded) {
      _reloadedAt = DateTime.now();
      Future<void>.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final seed = widget.reloaded ? const Color(0xFF027DFD) : Colors.deepPurple;
    final title = widget.reloaded ? 'Funciona en mi máquina' : 'Flutter Demo Home Page';
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      fontFamily: DeckFonts.sans,
    );
    final toast = _reloadedAt != null &&
        DateTime.now().difference(_reloadedAt!) < const Duration(milliseconds: 2500);
    return Column(
      children: [
        Container(
          width: 368,
          height: 624,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF05070B),
            borderRadius: BorderRadius.circular(64),
            border: Border.all(color: widget.frame, width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(52),
            // Un celular pequeño (330 puntos de ancho), ampliado.
            child: FittedBox(
              child: SizedBox(
                width: 330,
                height: 574,
                child: AnimatedTheme(
                  data: theme,
                  duration: Motion.slow,
                  child: Builder(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                        title: Text(title),
                      ),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('You have pushed the button this many times:'),
                            Text(
                              '${widget.count}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                      floatingActionButton: ExcludeFocus(
                        child: FloatingActionButton(
                          onPressed: () => DeckScope.of(context).live.tap(),
                          tooltip: 'Increment',
                          child: const Icon(Icons.add),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedOpacity(
          opacity: toast ? 1 : 0,
          duration: Motion.quick,
          child: Text.rich(
            const TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.local_fire_department, color: Color(0xFFFF8A3D), size: 26),
                ),
                TextSpan(text: ' Reloaded 1 of 812 libraries in 248ms.'),
              ],
            ),
            style: DeckType.monoSmall.copyWith(color: context.colors.muted),
          ),
        ),
      ],
    );
  }
}

class _WhyFast extends StatelessWidget {
  const _WhyFast();

  @override
  Widget build(BuildContext context) {
    return SlideScaffold(
      title: '¿Por qué tan rápido?',
      lead: 'Dart se compila de tres maneras, según el momento.',
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InfoCard(
              icon: Icons.bolt,
              title: 'Mientras programas',
              body: 'JIT: compila al vuelo. Por eso el hot reload tarda menos '
                  'de un segundo.',
              footer: 'flutter run',
            ),
          ),
          SizedBox(width: 28),
          Expanded(
            child: InfoCard(
              icon: Icons.memory,
              title: 'En producción',
              body: 'AOT: código máquina para ARM y x64. Arranca rápido y no '
                  'carga un intérprete.',
              footer: 'flutter build apk · ipa',
            ),
          ),
          SizedBox(width: 28),
          Expanded(
            child: InfoCard(
              icon: Icons.language,
              title: 'En la web',
              body: 'JavaScript o WebAssembly, a partir del mismo código.',
              footer: 'flutter build web --wasm',
            ),
          ),
        ],
      ),
    );
  }
}

/// Cada paso envuelve al anterior: el código crece por fuera, como una
/// cebolla, y a la derecha se ve lo que pinta. El código es el de verdad:
/// sale de lib/demos/tarjeta.dart, que es lo que corre la vista previa.
const _cardSteps = [
  (
    code: '''
Text('Funciona en mi máquina.')''',
    focus: <int>{1},
    note: 'Un widget. Ya es una app (fea, pero app).',
  ),
  (
    code: '''
Column(
  children: [
    Text('Funciona en mi máquina.'),
    Text('— Todo dev, alguna vez'),
  ],
)''',
    focus: <int>{1, 2, 5, 6},
    note: 'Column apila a sus hijos de arriba abajo.',
  ),
  (
    code: '''
Card(
  child: Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text('Funciona en mi máquina.'),
        Text('— Todo dev, alguna vez'),
      ],
    ),
  ),
)''',
    focus: <int>{1, 2, 3, 5, 6, 12, 13},
    note: 'Card y Padding envuelven. No hay CSS: el estilo también es widget.',
  ),
  (
    code: '''
Card(
  child: Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(spacing: 8, children: [Icon(Icons.bug_report), Text('Excusómetro')]),
        Text('Funciona en mi máquina.'),
        Text('— Todo dev, alguna vez'),
      ],
    ),
  ),
)''',
    focus: <int>{8},
    note: 'Row pone a sus hijos en fila. Icon trae miles de íconos de Material.',
  ),
  (
    code: '''
Card(
  child: Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(spacing: 8, children: [Icon(Icons.bug_report), Text('Excusómetro')]),
        Text(excusa, style: TextStyle(fontSize: 28)),
        Text('— Todo dev, alguna vez'),
        FilledButton(onPressed: otraExcusa, child: Text('Otra excusa')),
      ],
    ),
  ),
)''',
    focus: <int>{9, 11, 12, 13, 14, 15},
    note: 'Y ahí está la firma de todo dev de Flutter: ),),),',
  ),
];

class _CardComposer extends StatefulWidget {
  const _CardComposer({required this.step});

  final int step;

  @override
  State<_CardComposer> createState() => _CardComposerState();
}

class _CardComposerState extends State<_CardComposer> {
  int _excuse = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final step = widget.step;
    final current = _cardSteps[step];
    return SlideScaffold(
      title: 'Armemos una tarjeta',
      lead: 'Cada paso envuelve al anterior. Así se arma todo en Flutter.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CodeBlock(
                  code: current.code,
                  fileName: 'lib/excusometro.dart',
                  fontSize: 21,
                  minLines: 15,
                  focus: current.focus,
                ),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: Motion.base,
                  child: Text(
                    current.note,
                    key: ValueKey(step),
                    style: DeckType.small.copyWith(color: colors.muted),
                  ),
                ),
                if (step == _cardSteps.length - 1) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Tip: el editor escribe «// Column» junto a cada cierre '
                    '(closing labels). Nadie cuenta paréntesis a mano.',
                    style: DeckType.caption.copyWith(color: colors.faint),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 56),
          SizedBox(
            width: 470,
            height: 560,
            child: _Preview(
              step: step,
              excuse: excuses[_excuse % excuses.length],
              onAnother: () => setState(() => _excuse++),
            ),
          ),
        ],
      ),
    );
  }
}

/// La vista previa: corre el código del paso actual (lib/demos/tarjeta.dart)
/// dentro de una pantalla con scroll, como el cuerpo de una app real.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.step,
    required this.excuse,
    required this.onAnother,
  });

  final int step;
  final String excuse;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = demoTheme(colors.brightness);
    final content = switch (step) {
      0 => tarjeta.paso1(),
      1 => tarjeta.paso2(),
      2 => tarjeta.paso3(),
      3 => tarjeta.paso4(),
      _ => tarjeta.paso5(excuse, onAnother),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: colors.line, width: Space.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Text(
              'vista previa · el mismo código',
              style: DeckType.monoSmall.copyWith(color: colors.faint),
            ),
          ),
          // Una pantalla de celular de verdad (380 puntos de ancho, letra de
          // 14), ampliada para que se lea desde el fondo.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 34, 16, 16),
              child: FittedBox(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 360,
                  height: 370,
                  child: Theme(
                    data: theme,
                    child: Material(
                      color: theme.colorScheme.surface,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          AnimatedSwitcher(
                            duration: Motion.base,
                            child: GuideBox(
                              key: ValueKey(step),
                              outset: 6,
                              child: content,
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
        ],
      ),
    );
  }
}
