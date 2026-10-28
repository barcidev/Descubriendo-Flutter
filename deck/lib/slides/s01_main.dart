import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../engine/overview.dart';
import '../engine/slide.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/code_block.dart';
import '../ui/flutter_lockup.dart';
import '../ui/guide_box.dart';
import '../ui/overflow_stripes.dart';
import '../ui/reveal.dart';
import '../ui/slide_scaffold.dart';
import '../ui/terminal.dart';
import 'sections.dart';

final mainSlides = [
  Slide(
    id: 'arranque',
    section: mainSection,
    title: 'Arranque',
    chrome: false,
    builder: (context, step) => const _Boot(),
  ),
  Slide(
    id: 'agenda',
    section: mainSection,
    title: 'La agenda (con overflow)',
    steps: 2,
    builder: (context, step) => _Agenda(fixed: step >= 1),
  ),
];

// La salida de `flutter run`, tal cual la imprime la herramienta (capturada
// en esta misma máquina: por eso el «9,8s» lleva coma).
const _bootLines = [
  TermLine.command('flutter run -d chrome'),
  TermLine(
    'Launching lib/main.dart on Chrome in debug mode...',
    pause: Duration(milliseconds: 260),
  ),
  TermLine(
    'Waiting for connection from debug service on Chrome...         9,8s',
    pause: Duration(milliseconds: 1300),
  ),
  TermLine(''),
  TermLine('Flutter run key commands.', pause: Duration(milliseconds: 240)),
  TermLine('r Hot reload. {fire}{fire}{fire}', tone: TermTone.accent),
  TermLine('R Hot restart.'),
  TermLine('h List all available interactive commands.'),
  TermLine(
    'd Detach (terminate "flutter run" but leave application running).',
  ),
  TermLine('c Clear the screen'),
  TermLine('q Quit (terminate the application on the device).'),
];

/// La portada arranca como arranca cualquier app de Flutter: con
/// `flutter run`. Cuando la terminal termina, aparece la charla.
class _Boot extends StatefulWidget {
  const _Boot();

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  /// El título entra cuando la terminal ya casi se fue.
  static const _afterTerminal = Duration(milliseconds: 380);

  bool _booted = false;
  Timer? _settle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Thumbnail.of(context)) _booted = true;
  }

  void _onBooted() {
    _settle ??= Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _booted = true);
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hero = DeckType.hero.copyWith(color: colors.ink);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: Space.pageX,
          top: 170,
          width: 1240,
          child: AnimatedOpacity(
            opacity: _booted ? 0 : 1,
            duration: Motion.slow,
            curve: Motion.out,
            child: AnimatedScale(
              scale: _booted ? 0.97 : 1,
              duration: Motion.slow,
              curve: Motion.emphasized,
              alignment: Alignment.topLeft,
              child: Terminal(
                lines: _bootLines,
                title: 'zsh · charla',
                minLines: 12,
                onDone: _onBooted,
              ),
            ),
          ),
        ),
        Positioned(
          left: Space.pageX,
          right: Space.pageX,
          top: 196,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Reveal(
                visible: _booted,
                delay: _afterTerminal,
                child: Text(
                  '// ${Config.organizers.first} · ${Config.venue}',
                  style: DeckType.monoLabel.copyWith(
                    fontSize: 24,
                    color: colors.accentText,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              Reveal(
                visible: _booted,
                delay: _afterTerminal + const Duration(milliseconds: 120),
                child: GuideBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(Config.title, style: hero),
                      const SizedBox(height: 14),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Creando experiencias móviles ',
                            ),
                            TextSpan(
                              text: 'multiplataforma',
                              style: TextStyle(color: colors.accentText),
                            ),
                          ],
                        ),
                        style: DeckType.title.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w500,
                          fontVariations: const [
                            FontVariation('wght', 470),
                            FontVariation('opsz', 72),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Reveal(
                visible: _booted,
                delay: _afterTerminal + const Duration(milliseconds: 220),
                child: Text(
                  'o cómo dejar de decir «funciona en mi máquina»',
                  style: DeckType.mono.copyWith(color: colors.muted),
                ),
              ),
              const SizedBox(height: 84),
              Reveal(
                visible: _booted,
                delay: _afterTerminal + const Duration(milliseconds: 320),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Config.presenter,
                          style: DeckType.headline.copyWith(color: colors.ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Config.role,
                          style: DeckType.body.copyWith(color: colors.muted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      Config.date,
                      style: DeckType.mono.copyWith(color: colors.faint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: Space.pageX,
          right: Space.pageX,
          bottom: 64,
          child: Reveal(
            visible: _booted,
            delay: _afterTerminal + const Duration(milliseconds: 420),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FlutterLockup(height: 46),
                SizedBox(width: 40),
                Expanded(child: TrademarkNote()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

const _agendaItems = [
  ('¿Qué es Flutter?', 'flutter --version', 5),
  ('¿Qué se puede hacer?', 'flutter devices', 3),
  ('¿Cuándo sí y cuándo no?', 'flutter analyze', 5),
  ('¿Cómo se programa?', 'build(context)', 8),
  ('Dart y sus primos', 'dart migrate', 5),
  ('Construir una app', 'flutter create', 6),
  ('Recomendaciones', 'flutter pub add', 3),
  ('La demo', 'flutter run', 3),
  ('Preguntas', 'stdin', 4),
];

const _agendaColumn = '''
@override
Widget build(BuildContext context) {
  return Column(
    children: const [
      QueEsFlutter(),
      QueSePuedeHacer(),
      CuandoSiYCuandoNo(),
      ComoSePrograma(),
      DartYSusPrimos(),
      ConstruirUnaApp(),
      Recomendaciones(),
      LaDemo(),
      Preguntas(),
    ],
  );
}''';

const _agendaScroll = '''
@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      children: const [
        QueEsFlutter(),
        QueSePuedeHacer(),
        CuandoSiYCuandoNo(),
        ComoSePrograma(),
        DartYSusPrimos(),
        ConstruirUnaApp(),
        Recomendaciones(),
        LaDemo(),
        Preguntas(),
      ],
    ),
  );
}''';

/// La agenda es un widget, y como todo primer intento… se desborda.
class _Agenda extends StatelessWidget {
  const _Agenda({required this.fixed});

  final bool fixed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'La agenda de hoy, en un widget',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CodeBlock(
                  code: fixed ? _agendaScroll : _agendaColumn,
                  fileName: 'lib/charla.dart',
                  fontSize: 21,
                  minLines: 18,
                  focus: fixed ? const {3, 4, 16} : const {},
                ),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: Motion.base,
                  child: fixed
                      ? Row(
                          key: const ValueKey('ok'),
                          children: [
                            Icon(Icons.check_circle, color: colors.success, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Arreglado. Así se arreglan los overflows, de paso.',
                              style: DeckType.small.copyWith(color: colors.muted),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('error'),
                          children: [
                            Icon(Icons.error, color: colors.danger, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Nueve secciones en 45 minutos. ¿Qué podría salir mal?',
                              style: DeckType.small.copyWith(color: colors.muted),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 72),
          AgendaPreview(fixed: fixed),
        ],
      ),
    );
  }
}

/// Lo que ese `build` pinta: un teléfono con la agenda. Sin scroll, la
/// lista no cabe y aparece la franja de overflow.
class AgendaPreview extends StatefulWidget {
  const AgendaPreview({required this.fixed, super.key});

  final bool fixed;

  @override
  State<AgendaPreview> createState() => _AgendaPreviewState();
}

class _AgendaPreviewState extends State<AgendaPreview>
    with SingleTickerProviderStateMixin {
  late final _scroll = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  static const _screenHeight = 588.0;
  static const _rowHeight = 84.0;
  static const _header = 76.0;

  @override
  void didUpdateWidget(AgendaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    final still = Thumbnail.of(context) || Motion.reduced(context);
    if (widget.fixed && !still) {
      if (!_scroll.isAnimating) _scroll.repeat(reverse: true);
    } else {
      _scroll
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const listHeight = _rowHeight * 9;
    const overflow = listHeight - (_screenHeight - _header);
    return Container(
      width: 470,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.isNight ? const Color(0xFF0A1630) : const Color(0xFF1B2638),
        borderRadius: BorderRadius.circular(54),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(42),
        child: Container(
          height: _screenHeight,
          color: colors.surface,
          child: Column(
            children: [
              Container(
                height: _header,
                padding: const EdgeInsets.fromLTRB(30, 24, 30, 0),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      'Charla',
                      style: DeckType.headline.copyWith(
                        fontSize: 30,
                        color: colors.ink,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '45 min',
                      style: DeckType.monoSmall.copyWith(color: colors.faint),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          maxHeight: listHeight,
                          child: AnimatedBuilder(
                            animation: _scroll,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(
                                0,
                                -Curves.easeInOut.transform(_scroll.value) *
                                    overflow,
                              ),
                              child: child,
                            ),
                            child: Column(
                              children: [
                                for (final (index, item) in _agendaItems.indexed)
                                  _AgendaRow(index: index, item: item),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedOpacity(
                        opacity: widget.fixed ? 0 : 1,
                        duration: Motion.base,
                        child: const OverflowStripes(
                          label: 'BOTTOM OVERFLOWED BY 45 MINUTES',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.index, required this.item});

  final int index;
  final (String, String, int) item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (title, command, minutes) = item;
    return Container(
      height: _AgendaPreviewState._rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Row(
        children: [
          Text(
            (index + 1).toString().padLeft(2, '0'),
            style: DeckType.monoSmall.copyWith(color: colors.faint),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DeckType.small.copyWith(fontSize: 24, color: colors.ink),
                ),
                Text(
                  command,
                  style: DeckType.monoSmall.copyWith(
                    fontSize: 16,
                    color: colors.accentText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$minutes min',
            style: DeckType.monoSmall.copyWith(color: colors.faint),
          ),
        ],
      ),
    );
  }
}
