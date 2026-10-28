import 'package:material_ui/material_ui.dart';

import '../engine/deck_scope.dart';
import '../engine/overview.dart';
import '../engine/slide.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/app_frame.dart';
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
  TermLine.command('flutter run -d chrome --release'),
  TermLine('Launching lib/main.dart on Chrome in release mode...', pause: Duration(milliseconds: 500)),
  TermLine(
    'Compiling lib/main.dart for the Web...          14,8s',
    pause: Duration(milliseconds: 2200),
  ),
  TermLine('✓ Built build/web', tone: TermTone.success, pause: Duration(milliseconds: 500)),
  TermLine('Application started: EcoEats', tone: TermTone.accent, pause: Duration(milliseconds: 400)),
];

/// El tamaño de la pantalla del celular, en puntos (un iPhone 16e).
const _screen = Size(390, 844);

/// Fondo del splash de EcoEats (flutter_native_splash.yaml).
const _splashColor = Color(0xFFF4EEE4);

/// La única diapositiva que habla de EcoEats: la app real, corriendo dentro
/// de la charla. Primero «compila», después el simulador la abre como un
/// celular, y queda para que cualquiera la pruebe.
class _Demo extends StatefulWidget {
  const _Demo({required this.step});

  final int step;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> with SingleTickerProviderStateMixin {
  late final _launch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Thumbnail.of(context) || Motion.reduced(context)) _launch.value = 1;
  }

  @override
  void dispose() {
    _launch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scope = DeckScope.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        SlideScaffold(
          title: 'Todo esto, en una app real',
          lead: 'EcoEats: Flutter en el celular, una API en Kotlin en la nube.',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Terminal(
                      lines: _runLines,
                      title: 'zsh · demo',
                      fontSize: 22,
                      onDone: () {
                        if (mounted && _launch.value == 0) _launch.forward();
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Pruébenla: no es un video, es la app corriendo aquí.',
                      style: DeckType.headline.copyWith(fontSize: 34, color: colors.accentText),
                    ),
                    const SizedBox(height: 28),
                    Reveal(
                      visible: widget.step >= 1,
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
              const SizedBox(width: 560),
            ],
          ),
        ),
        Positioned(
          right: Space.pageX,
          top: 34,
          bottom: Space.statusBar + 22,
          child: AspectRatio(
            aspectRatio: (_screen.width + 28) / (_screen.height + 56),
            child: _Phone(
              launch: _launch,
              app: AppFrame(
                path: '/ecoeats/',
                placeholder: const _Splash(),
                onNext: scope.deck.next,
                onPrevious: scope.deck.previous,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Un celular dibujado: marco, pantalla con la app y, encima, el inicio
/// del simulador mientras arranca.
class _Phone extends StatelessWidget {
  const _Phone({required this.launch, required this.app});

  final Animation<double> launch;
  final Widget app;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Container(
        width: _screen.width + 28,
        height: _screen.height + 56,
        padding: const EdgeInsets.fromLTRB(14, 42, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF05070B),
          borderRadius: BorderRadius.circular(60),
          border: Border.all(color: const Color(0xFF2A3446), width: 3),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 18))],
        ),
        child: Stack(
          children: [
            // El parlante, arriba del borde: no tapa la app.
            Positioned(
              top: -26,
              left: _screen.width / 2 - 40,
              child: Container(
                width: 80,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2230),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(44),
              child: SizedBox.fromSize(
                size: _screen,
                child: AnimatedBuilder(
                  animation: launch,
                  builder: (context, _) => Stack(
                    children: [
                      Positioned.fill(child: app),
                      if (launch.value < 1)
                        Positioned.fill(child: _Launching(t: launch.value)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El arranque, como en iOS: el ícono crece desde su lugar hasta llenar la
/// pantalla con el splash, y el splash se desvanece sobre la app.
class _Launching extends StatelessWidget {
  const _Launching({required this.t});

  final double t;

  static final _iconRect = _HomeScreen.iconRect(5);

  @override
  Widget build(BuildContext context) {
    final grow = Motion.out.transform((t / 0.32).clamp(0, 1));
    final fade = 1 - Motion.inOut.transform(((t - 0.72) / 0.28).clamp(0, 1));
    final rect = Rect.lerp(_iconRect, Offset.zero & _screen, grow)!;
    return Stack(
      children: [
        if (fade > 0.99 || grow < 1) const Positioned.fill(child: _HomeScreen()),
        if (t > 0)
          Positioned.fromRect(
            rect: rect,
            child: Opacity(
              opacity: fade,
              child: Container(
                decoration: BoxDecoration(
                  color: _splashColor,
                  borderRadius: BorderRadius.circular(14 + 30 * grow),
                ),
                alignment: Alignment.center,
                child: grow < 0.35
                    ? Image.asset('assets/demo/ecoeats_icon.png', filterQuality: FilterQuality.medium)
                    : Image.asset(
                        'assets/demo/ecoeats_splash.png',
                        width: 220,
                        filterQuality: FilterQuality.medium,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

/// La pantalla de inicio del simulador, con EcoEats entre las demás apps.
class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  static const _columns = 4;
  static const _icon = 62.0;
  static const _top = 78.0;
  static const _rowHeight = 96.0;

  /// Dónde queda el ícono número [index] (de izquierda a derecha y de
  /// arriba abajo).
  static Rect iconRect(int index) {
    final gap = (_screen.width - _columns * _icon) / (_columns + 1);
    final column = index % _columns;
    final row = index ~/ _columns;
    return Rect.fromLTWH(gap + column * (_icon + gap), _top + row * _rowHeight, _icon, _icon);
  }

  static const _apps = [
    (Icons.settings, 'Ajustes', Color(0xFF8E8E93)),
    (Icons.photo, 'Fotos', Color(0xFFFF9F0A)),
    (Icons.photo_camera, 'Cámara', Color(0xFF3A3A3C)),
    (Icons.mail, 'Correo', Color(0xFF0A84FF)),
    (Icons.map, 'Mapas', Color(0xFF30D158)),
    (null, 'EcoEats', _splashColor),
    (Icons.schedule, 'Reloj', Color(0xFF1C1C1E)),
    (Icons.wb_sunny, 'Clima', Color(0xFF64D2FF)),
    (Icons.event, 'Calendario', Color(0xFFFF453A)),
    (Icons.music_note, 'Música', Color(0xFFFF375F)),
    (Icons.calculate, 'Calculadora', Color(0xFF636366)),
    (Icons.note, 'Notas', Color(0xFFFFD60A)),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FlutterBrand.navy, FlutterBrand.blue, Color(0xFF13B9FD)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 30,
            top: 16,
            child: Text(
              '6:00',
              style: TextStyle(
                fontFamily: DeckFonts.sans,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          const Positioned(
            right: 26,
            top: 16,
            child: Row(
              children: [
                Icon(Icons.signal_cellular_alt, size: 18, color: Color(0xFFFFFFFF)),
                SizedBox(width: 6),
                Icon(Icons.wifi, size: 18, color: Color(0xFFFFFFFF)),
                SizedBox(width: 6),
                Icon(Icons.battery_full, size: 18, color: Color(0xFFFFFFFF)),
              ],
            ),
          ),
          for (final (index, (icon, _, color)) in _apps.indexed)
            Positioned.fromRect(
              rect: iconRect(index),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: icon == null
                    ? Image.asset('assets/demo/ecoeats_icon.png', filterQuality: FilterQuality.medium)
                    : Icon(icon, color: const Color(0xFFFFFFFF), size: 32),
              ),
            ),
          for (final (index, (_, label, _)) in _apps.indexed)
            Positioned(
              left: iconRect(index).left - 12,
              top: iconRect(index).bottom + 6,
              width: _icon + 24,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: DeckFonts.sans,
                  fontSize: 12,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lo que se ve fuera del navegador (tests, miniaturas): el splash.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _splashColor,
      child: Center(
        child: Image.asset(
          'assets/demo/ecoeats_splash.png',
          width: 220,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
