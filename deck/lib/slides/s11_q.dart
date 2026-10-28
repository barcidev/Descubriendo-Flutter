import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../engine/deck_scope.dart';
import '../engine/overview.dart';
import '../engine/slide.dart';
import '../live/join_card.dart';
import '../live/live_controller.dart';
import '../live/live_models.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/flutter_lockup.dart';
import '../ui/qr_code.dart';
import '../ui/reveal.dart';
import '../ui/terminal.dart';
import 'sections.dart';

final quitSlides = [
  Slide(
    id: 'creditos',
    section: quitSection,
    title: 'Créditos',
    chrome: false,
    cue: (step) => const AudienceCue.credits(),
    builder: (context, step) => const _Credits(),
  ),
  Slide(
    id: 'application-finished',
    section: quitSection,
    title: 'Application finished.',
    chrome: false,
    cue: (step) => const AudienceCue.rating(),
    builder: (context, step) => const _Finished(),
  ),
];

/// Los créditos, como en el cine: suben despacio con los datos de la
/// charla, el elenco (el público, con su apodo) y quienes la organizan. Al
/// final, la escena post-créditos y, cinco segundos después, el Mac muestra
/// la app de verdad mientras la charla pasa sola al cierre.
class _Credits extends StatefulWidget {
  const _Credits();

  @override
  State<_Credits> createState() => _CreditsState();
}

class _CreditsState extends State<_Credits> with SingleTickerProviderStateMixin {
  static const _speed = 125.0;
  static const _longest = Duration(seconds: 60);

  late final Ticker _ticker = createTicker(_onTick);
  final _content = GlobalKey();
  double _travelled = 0;
  Duration _last = Duration.zero;
  bool _rolled = false;

  /// Segundos desde que terminó el rollo: la escena post-créditos.
  int _after = 0;
  Timer? _scene;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DeckScope.of(context).live.requestAttendees();
      if (!Thumbnail.of(context) && !Motion.reduced(context)) _ticker.start();
    });
  }

  double get _height => (_content.currentContext?.size?.height ?? 4000) + Canvas16x9.height;

  void _onTick(Duration elapsed) {
    final seconds = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    // Si el elenco es muy largo, sube más rápido: nunca más de un minuto.
    final speed = math.max(_speed, _height / _longest.inSeconds);
    setState(() => _travelled += seconds * speed);
    if (_travelled >= _height && !_rolled) {
      _rolled = true;
      _ticker.stop();
      _scene = Timer.periodic(const Duration(seconds: 1), (_) => _tickScene());
    }
  }

  /// La escena post-créditos dura doce segundos: el chiste a los siete y,
  /// cinco segundos después, al Mac.
  void _tickScene() {
    if (!mounted) return;
    setState(() => _after++);
    if (_after == 12) {
      _scene?.cancel();
      final scope = DeckScope.of(context);
      unawaited(scope.browser.showDemoApps());
      final finale = scope.deck.slides.indexWhere((slide) => slide.id == 'application-finished');
      if (finale >= 0 && scope.deck.slide.id == 'creditos') scope.deck.goTo(finale);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scene?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = DeckScope.of(context);
    final slides = scope.deck.slides.length;
    return ColoredBox(
      color: const Color(0xFF000000),
      child: _rolled
          ? _PostCredits(seconds: _after, slides: slides)
          : ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: double.infinity,
                child: Transform.translate(
                  offset: Offset(0, Canvas16x9.height - _travelled),
                  child: ListenableBuilder(
                    listenable: scope.live,
                    builder: (context, _) => KeyedSubtree(
                      key: _content,
                      child: _Roll(live: scope.live, slides: slides),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Todo lo que sube en los créditos.
class _Roll extends StatelessWidget {
  const _Roll({required this.live, required this.slides});

  final LiveController live;
  final int slides;

  static const _roles = [
    ('Dirección de arte', 'CustomPainter'),
    ('Efectos especiales', 'Impeller'),
    ('Coreografía', 'AnimatedContainer'),
    ('Vestuario', 'ThemeData, claro y oscuro'),
    ('Continuidad', 'setState'),
    ('Montaje', 'Hot reload'),
    ('Doble de riesgo', 'flutter clean'),
    ('Jurado de excusas', 'Gemini'),
    ('Sonido', 'el aire acondicionado del auditorio'),
    ('Catering', 'el café (dos tazas, mínimo)'),
  ];

  @override
  Widget build(BuildContext context) {
    final cast = live.attendees;
    return SizedBox(
      width: Canvas16x9.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _big(Config.title.toUpperCase(), spacing: 10),
          const SizedBox(height: 10),
          _small(Config.subtitle),
          const SizedBox(height: 140),
          _heading('Una charla de'),
          const SizedBox(height: 36),
          ClipOval(
            child: Image.asset(Config.presenterPhoto, width: 240, height: 240, fit: BoxFit.cover),
          ),
          const SizedBox(height: 28),
          _big(Config.presenter),
          const SizedBox(height: 8),
          _small(Config.role),
          const SizedBox(height: 140),
          for (final (role, name) in _roles) _role(role, name),
          const SizedBox(height: 140),
          _heading('La charla en números'),
          const SizedBox(height: 36),
          _role('Diapositivas', '$slides (todas widgets)'),
          _role('Personas conectadas', '${math.max(live.people, live.connected)}'),
          _role('Toques al contador', '${live.counter}'),
          _role('Excusas recibidas', '${live.excuseRound.received}'),
          _role('Preguntas', '${live.questionRound.received}'),
          _role('Votos', '${live.totalVotes}'),
          const SizedBox(height: 140),
          _heading('Elenco, por orden de llegada'),
          const SizedBox(height: 40),
          if (cast.isEmpty)
            _big('Ustedes')
          else
            SizedBox(
              width: 1500,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 18,
                children: [
                  for (final person in cast)
                    SizedBox(
                      width: 470,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: person.name),
                            TextSpan(
                              text: '  ${asCall(person.widget)}',
                              style: DeckType.monoSmall.copyWith(
                                fontSize: 22,
                                color: const Color(0xFF5BAAFF),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DeckType.small.copyWith(fontSize: 30, color: const Color(0xFFEEF4FF)),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 140),
          _heading('Con la participación especial de'),
          const SizedBox(height: 36),
          for (final name in const [
            'Dash, el colibrí',
            'El Excusómetro',
            'El contador más grande del mundo',
            'La ruleta de la culpa',
            'EcoEats',
          ])
            Padding(padding: const EdgeInsets.only(bottom: 14), child: _medium(name)),
          const SizedBox(height: 140),
          _heading('Organizan'),
          const SizedBox(height: 40),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 28,
            runSpacing: 28,
            children: [
              for (final (logo, name) in Config.organizerLogos) _logo(logo, name),
            ],
          ),
          const SizedBox(height: 90),
          _heading('Sede'),
          const SizedBox(height: 36),
          _logo(Config.venueLogo, Config.venue),
          const SizedBox(height: 24),
          _small('${Config.city} · ${Config.date}'),
          const SizedBox(height: 140),
          _heading('Hecha con'),
          const SizedBox(height: 36),
          const FlutterLockup(height: 72),
          const SizedBox(height: 18),
          _small('Flutter 3.47 · Dart 3.13 · y un servidor en Dart'),
          const SizedBox(height: 24),
          const SizedBox(width: 1100, child: TrademarkNote()),
          const SizedBox(height: 160),
          _medium('Ningún widget fue maltratado durante esta charla.'),
          const SizedBox(height: 12),
          _small('Bueno, el Padding sí. Un poquito.'),
          const SizedBox(height: 200),
        ],
      ),
    );
  }

  Widget _heading(String text) => Text(
    text.toUpperCase(),
    textAlign: TextAlign.center,
    style: DeckType.monoLabel.copyWith(
      fontSize: 22,
      letterSpacing: 6,
      color: const Color(0xFF94A8C8),
    ),
  );

  Widget _big(String text, {double spacing = 0}) => Text(
    text,
    textAlign: TextAlign.center,
    style: DeckType.display.copyWith(color: const Color(0xFFFFFFFF), letterSpacing: spacing),
  );

  Widget _medium(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: DeckType.headline.copyWith(color: const Color(0xFFEEF4FF)),
  );

  Widget _small(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: DeckType.small.copyWith(color: const Color(0xFF94A8C8)),
  );

  /// Cargo a la izquierda, nombre a la derecha, como en el cine.
  Widget _role(String role, String name) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 640,
          child: Text(
            role,
            textAlign: TextAlign.right,
            style: DeckType.small.copyWith(fontSize: 30, color: const Color(0xFF94A8C8)),
          ),
        ),
        const SizedBox(width: 48),
        SizedBox(
          width: 640,
          child: Text(
            name,
            style: DeckType.headline.copyWith(fontSize: 36, color: const Color(0xFFFFFFFF)),
          ),
        ),
      ],
    ),
  );

  Widget _logo(String asset, String name) => Container(
    height: 120,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(Radii.md),
    ),
    child: Image.asset(asset, semanticLabel: name, filterQuality: FilterQuality.medium),
  );
}

/// La escena post-créditos: el chiste y la cuenta regresiva hacia el Mac.
class _PostCredits extends StatelessWidget {
  const _PostCredits({required this.seconds, required this.slides});

  final int seconds;
  final int slides;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    const grey = Color(0xFF94A8C8);
    final left = 12 - seconds;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 200),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(
            visible: seconds >= 0,
            child: Text(
              'ESCENA POST-CRÉDITOS',
              style: DeckType.monoLabel.copyWith(fontSize: 22, letterSpacing: 6, color: grey),
            ),
          ),
          const SizedBox(height: 40),
          Reveal(
            visible: seconds >= 1,
            child: Text(
              '¿Creyeron que todo esto eran diapositivas?',
              style: DeckType.display.copyWith(color: white),
            ),
          ),
          const SizedBox(height: 28),
          Reveal(
            visible: seconds >= 4,
            child: Text(
              'Era un mock: $slides widgets haciéndose pasar por PowerPoint.',
              style: DeckType.headline.copyWith(fontSize: 52, color: const Color(0xFF5BAAFF)),
            ),
          ),
          const SizedBox(height: 56),
          Reveal(
            visible: seconds >= 7,
            child: Text(
              left > 0
                  ? 'Y ahora, la app de verdad, en mi Mac. En $left…'
                  : 'Y ahora, la app de verdad.',
              style: DeckType.headline.copyWith(fontSize: 40, color: grey),
            ),
          ),
        ],
      ),
    );
  }
}

const _getStarted = 'https://docs.flutter.dev/get-started';

const _quitLines = [
  TermLine.command('q', pause: Duration(milliseconds: 500)),
  TermLine('Application finished.', pause: Duration(milliseconds: 500)),
];

const _captions = [
  'Segmentation fault',
  'Compila con warnings',
  'Funciona en mi máquina',
  'Pasa los tests',
  'Deploy un viernes y nada se rompió',
];

/// El cierre: «Application finished.», las gracias y, al lado, la
/// calificación en vivo. Aquí vuelve la charla después de la demo en el Mac.
class _Finished extends StatelessWidget {
  const _Finished();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.pageX, 80, Space.pageX, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 700,
                        child: Terminal(lines: _quitLines, title: 'zsh · charla', fontSize: 26),
                      ),
                      const SizedBox(height: 56),
                      EnterOnce(
                        delay: const Duration(milliseconds: 1600),
                        child: Text('Gracias.', style: DeckType.hero.copyWith(color: colors.ink)),
                      ),
                      const SizedBox(height: 18),
                      EnterOnce(
                        delay: const Duration(milliseconds: 1800),
                        child: Row(
                          children: [
                            ClipOval(
                              child: Image.asset(
                                Config.presenterPhoto,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Config.presenter,
                                  style: DeckType.headline.copyWith(color: colors.ink),
                                ),
                                Text(
                                  Config.role,
                                  style: DeckType.small.copyWith(color: colors.muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Para empezar mañana: la guía oficial, para escanear al salir.
                      EnterOnce(
                        delay: const Duration(milliseconds: 2000),
                        child: Row(
                          children: [
                            const QrCode(data: _getStarted, size: 190),
                            const SizedBox(width: 28),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Para empezar mañana',
                                  style: DeckType.headline.copyWith(fontSize: 34, color: colors.ink),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'docs.flutter.dev/get-started',
                                  style: DeckType.mono.copyWith(color: colors.accentText),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 56),
                SizedBox(
                  width: 780,
                  child: ListenableBuilder(
                    listenable: live,
                    builder: (context, _) => _Rating(live: live),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              for (final (logo, name) in Config.organizerLogos) ...[
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Image.asset(logo, semanticLabel: name, filterQuality: FilterQuality.medium),
                ),
                const SizedBox(width: 16),
              ],
              const Spacer(),
              const FlutterLockup(height: 40),
            ],
          ),
          const SizedBox(height: 16),
          const TrademarkNote(),
        ],
      ),
    );
  }
}

/// La calificación en vivo, con las leyendas de cada estrella.
class _Rating extends StatelessWidget {
  const _Rating({required this.live});

  final LiveController live;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '¿Cómo estuvo? Califiquen el deploy',
                style: DeckType.headline.copyWith(fontSize: 40, color: colors.ink),
              ),
            ),
            const SizedBox(width: 24),
            const JoinCard(qrSize: 150, compact: true),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: live.rating),
              duration: Motion.slow,
              builder: (context, value, _) => Text(
                live.ratings == 0 ? '?.?' : value.toStringAsFixed(1),
                style: DeckType.hero.copyWith(
                  fontSize: 150,
                  color: live.ratings == 0 ? colors.faint : colors.ink,
                  fontFeatures: DeckType.tabular,
                ),
              ),
            ),
            const SizedBox(width: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (var star = 1; star <= 5; star++)
                      Icon(
                        star <= live.rating.round() ? Icons.star : Icons.star_border,
                        size: 48,
                        color: const Color(0xFFFFD25E),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${live.ratings} calificaciones',
                  style: DeckType.mono.copyWith(color: colors.muted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final (index, caption) in _captions.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 82,
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}',
                        style: DeckType.monoSmall.copyWith(color: const Color(0xFFFFD25E)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 22, color: Color(0xFFFFD25E)),
                    ],
                  ),
                ),
                Text(caption, style: DeckType.small.copyWith(fontSize: 24, color: colors.muted)),
              ],
            ),
          ),
      ],
    );
  }
}
