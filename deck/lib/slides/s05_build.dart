import 'package:material_ui/material_ui.dart';

import '../demos/excusometro.dart';
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
    cue: (step) => const AudienceCue.excuse(),
    builder: (context, step) => const _LiveExcuses(),
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

class _LiveExcuses extends StatelessWidget {
  const _LiveExcuses();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    return SlideScaffold(
      title: 'Mándame tu mejor excusa de dev',
      lead: 'La que más has usado. Si pasa el code review, sale aquí.',
      trailing: const JoinCard(qrSize: 170, compact: true),
      child: ListenableBuilder(
        listenable: live,
        builder: (context, _) {
          final latest = live.excuses.isEmpty ? null : live.excuses.first;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 640,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Theme(
                      data: demoTheme(colors.brightness),
                      child: ExcuseCard(
                        excuse: latest?.text ?? excuses.first,
                        author: latest == null ? excuseAuthor : '— ${latest.author}()',
                      ),
                    ),
                    const SizedBox(height: 32),
                    const CodeBlock(
                      code: '''
ListenableBuilder(
  listenable: sala,
  builder: (context, _) =>
      ExcuseCard(excuse: sala.ultima),
)''',
                      fileName: 'excusometro.dart',
                      fontSize: 21,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 64),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${live.excuses.length} excusas aprobadas',
                      style: DeckType.monoLabel.copyWith(color: colors.accentText),
                    ),
                    const SizedBox(height: 18),
                    for (final excuse in live.excuses.skip(1).take(6))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          '«${excuse.text}»  — ${excuse.author}()',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DeckType.small.copyWith(color: colors.muted),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      'Llega una excusa, cambia el estado, Flutter repinta. '
                      'Nadie tocó la tarjeta.',
                      style: DeckType.small.copyWith(color: colors.faint),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
      trailing: ListenableBuilder(
        listenable: live,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${live.counter}',
              style: DeckType.display.copyWith(
                color: colors.ink,
                fontFeatures: DeckType.tabular,
              ),
            ),
            Text('toques', style: DeckType.monoSmall.copyWith(color: colors.faint)),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CodeBlock(
            code: step == 0 ? _templateBefore : _templateAfter,
            fileName: 'contador/lib/main.dart · la plantilla de flutter create',
            fontSize: 23,
            focus: const {6, 8},
          ),
          const SizedBox(height: 36),
          PointList(
            visible: step + 2,
            gap: 12,
            style: DeckType.headline.copyWith(fontSize: 32),
            points: const [
              ('Cambio el color y el título, y guardo', null),
              ('En menos de un segundo, la app cambia', null),
              ('Y el número no vuelve a cero: el estado se conserva', null),
            ],
          ),
        ],
      ),
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
/// cebolla, y a la derecha se ve lo que pinta.
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
      children: [
        Text('Funciona en mi máquina.'),
        Text('— Todo dev, alguna vez'),
      ],
    ),
  ),
)''',
    focus: <int>{1, 2, 3, 10, 11},
    note: 'Card y Padding envuelven. No hay CSS: el estilo también es widget.',
  ),
  (
    code: '''
Card(
  child: Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      children: [
        Row(children: [Icon(Icons.bug_report), Text('Excusómetro')]),
        Text('Funciona en mi máquina.'),
        Text('— Todo dev, alguna vez'),
      ],
    ),
  ),
)''',
    focus: <int>{6},
    note: 'Row pone a sus hijos en fila. Icon trae miles de íconos de Material.',
  ),
  (
    code: '''
Card(
  child: Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      children: [
        Row(children: [Icon(Icons.bug_report), Text('Excusómetro')]),
        Text(excusa),
        Text('— Todo dev, alguna vez'),
        FilledButton(onPressed: otraExcusa, child: Text('Otra excusa')),
      ],
    ),
  ),
)''',
    focus: <int>{7, 9, 10, 11, 12, 13},
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
                  fontSize: 22,
                  minLines: 13,
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
            width: 540,
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

/// La vista previa: lo que pinta el código del paso actual, de verdad.
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
    // El tema crudo no trae tamaños de letra: los pone Theme.of al
    // localizarlo, así que los estilos se piden adentro del Theme.
    final text = Theme.of(context).textTheme.apply(
      fontFamily: DeckFonts.sans,
      bodyColor: theme.colorScheme.onSurface,
    );
    final Widget content = switch (step) {
      0 => Text('Funciona en mi máquina.', style: text.bodyLarge),
      1 => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Funciona en mi máquina.', style: text.bodyLarge),
          Text(excuseAuthor, style: text.bodyLarge),
        ],
      ),
      2 => const SizedBox(
        width: 470,
        child: ExcuseCard(excuse: 'Funciona en mi máquina.', header: false),
      ),
      3 => const SizedBox(
        width: 470,
        child: ExcuseCard(excuse: 'Funciona en mi máquina.'),
      ),
      _ => SizedBox(
        width: 470,
        child: ExcuseCard(excuse: excuse, onAnother: onAnother),
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: colors.line, width: Space.hairline),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 18,
            child: Text(
              'vista previa · en vivo',
              style: DeckType.monoSmall.copyWith(color: colors.faint),
            ),
          ),
          Center(
            child: Theme(
              data: theme,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: AnimatedSize(
                  duration: Motion.base,
                  curve: Motion.emphasized,
                  child: AnimatedSwitcher(
                    duration: Motion.base,
                    child: GuideBox(
                      key: ValueKey(step),
                      outset: 10,
                      child: content,
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
