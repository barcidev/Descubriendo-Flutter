import 'package:material_ui/material_ui.dart';

import '../engine/deck_scope.dart';
import '../engine/overview.dart';
import '../engine/slide.dart';
import '../live/live_controller.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
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
    // Sin barra de estado: el celular usa todo el alto.
    chrome: false,
    builder: (context, step) => _Demo(step: step),
  ),
];

/// Dónde vive EcoEats web: la charla la carga desde que abre (ver
/// `Browser.preloadApp`).
const demoAppPath = '/ecoeats/';

const _runLines = [
  TermLine.command('flutter run -d "iPhone 17 Pro"'),
  TermLine('Launching lib/main.dart on iPhone 17 Pro in release mode...', pause: Duration(milliseconds: 500)),
  TermLine(
    'Compiling lib/main.dart...                         14,8s',
    pause: Duration(milliseconds: 1800),
  ),
  TermLine('✓ Built build/ios/iphonesimulator/Runner.app', tone: TermTone.success, pause: Duration(milliseconds: 400)),
  TermLine('Application started: EcoEats', tone: TermTone.accent, pause: Duration(milliseconds: 400)),
];

/// Fondo del splash de EcoEats (flutter_native_splash.yaml).
const _splashColor = Color(0xFFF4EEE4);

// Las medidas del iPhone dibujado, en puntos (como un iPhone 17 Pro).
const _screenWidth = 390.0;
const _screenHeight = 844.0;
const _screen = Size(_screenWidth, _screenHeight);
const _statusBar = 50.0;
const _homeBar = 22.0;
const _bezel = 12.0;
const _band = 4.0;
const _buttons = 4.0;
const _device = Size(
  _screenWidth + 2 * (_bezel + _band + _buttons),
  _screenHeight + 2 * (_bezel + _band),
);

/// La única diapositiva que habla de EcoEats: la app real, versión web,
/// corriendo dentro de un iPhone dibujado. La terminal «compila», el iPhone
/// la abre como un simulador y queda para que cualquiera la pruebe.
class _Demo extends StatefulWidget {
  const _Demo({required this.step});

  final int step;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> with SingleTickerProviderStateMixin {
  late final _launch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..addListener(_maybeShow);
  final _appArea = GlobalKey();
  late final DeckScope _scope = DeckScope.of(context);
  bool _shown = false;
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Thumbnail.of(context) || Motion.reduced(context)) _launch.value = 1;
    if (!_listening) {
      _listening = true;
      _scope.deck.addListener(_place);
      _scope.live.addListener(_place);
    }
  }

  /// Al terminar de crecer el splash, la app de verdad aparece encima.
  void _maybeShow() {
    if (_shown || _launch.value < 0.72) return;
    _shown = true;
    _place();
  }

  /// La app va sobre el área de la pantalla, salvo que haya algo encima de
  /// la diapositiva (la vista general, el QR, la pausa, los rayos X…).
  void _place() {
    if (!mounted) return;
    final deck = _scope.deck;
    final live = _scope.live;
    final covered = deck.overview ||
        deck.qr ||
        deck.paused ||
        deck.xray ||
        deck.slide.id != 'demo' ||
        live.access == PresenterAccess.login ||
        live.access == PresenterAccess.checking;
    if (!_shown || covered || Thumbnail.of(context)) {
      _scope.browser.placeApp(null);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_shown) return;
      final box = _appArea.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final topLeft = box.localToGlobal(Offset.zero);
      final bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero));
      _scope.browser.placeApp(Rect.fromPoints(topLeft, bottomRight));
    });
  }

  @override
  void dispose() {
    _scope.deck.removeListener(_place);
    _scope.live.removeListener(_place);
    _scope.browser.placeApp(null);
    _launch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Si cambia el tamaño de la ventana (o la pantalla completa), la app se
    // vuelve a acomodar.
    MediaQuery.sizeOf(context);
    _place();
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
              const SizedBox(width: 600),
            ],
          ),
        ),
        Positioned(
          right: Space.pageX - 30,
          top: 14,
          bottom: 14,
          child: AspectRatio(
            aspectRatio: _device.width / _device.height,
            child: FittedBox(
              child: SizedBox.fromSize(
                size: _device,
                child: _IPhone(
                  launch: _launch,
                  appArea: _appArea,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Un iPhone como el del simulador: borde de titanio, botones a los lados,
/// la isla dinámica y la barra de inicio.
class _IPhone extends StatelessWidget {
  const _IPhone({required this.launch, required this.appArea});

  final Animation<double> launch;
  final GlobalKey appArea;

  static const _titanium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9A9A9F), Color(0xFF3C3C40), Color(0xFF75757B), Color(0xFF2B2B2E)],
    stops: [0, 0.35, 0.7, 1],
  );

  @override
  Widget build(BuildContext context) {
    Widget button(double top, double height, {required bool left}) => Positioned(
      top: top,
      height: height,
      left: left ? 0 : null,
      right: left ? null : 0,
      width: _buttons + 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _titanium,
          borderRadius: BorderRadius.horizontal(
            left: left ? const Radius.circular(3) : Radius.zero,
            right: left ? Radius.zero : const Radius.circular(3),
          ),
        ),
      ),
    );
    return Stack(
      children: [
        // Botón de acción y volumen a la izquierda; encendido a la derecha.
        button(150, 34, left: true),
        button(212, 62, left: true),
        button(290, 62, left: true),
        button(236, 98, left: false),
        Positioned.fill(
          left: _buttons,
          right: _buttons,
          child: Container(
            padding: const EdgeInsets.all(_band),
            decoration: BoxDecoration(
              gradient: _titanium,
              borderRadius: BorderRadius.circular(70),
              boxShadow: const [
                BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 22)),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(_bezel),
              decoration: BoxDecoration(
                color: const Color(0xFF050506),
                borderRadius: BorderRadius.circular(66),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(54),
                child: SizedBox.fromSize(
                  size: _screen,
                  child: AnimatedBuilder(
                    animation: launch,
                    builder: (context, _) => _Screen(t: launch.value, appArea: appArea),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// La pantalla: la barra de estado con la isla, el área de la app (ahí se
/// pone la app de verdad) y, mientras arranca, el inicio del simulador.
class _Screen extends StatelessWidget {
  const _Screen({required this.t, required this.appArea});

  final double t;
  final GlobalKey appArea;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1C1C1E);
    return Stack(
      children: [
        // Debajo de la app: su splash, por si tarda un instante.
        const Positioned.fill(child: _Splash()),
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: _statusBar,
          child: ColoredBox(color: _splashColor),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: _statusBar,
          bottom: _homeBar,
          child: SizedBox.expand(key: appArea),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _homeBar,
          child: ColoredBox(
            color: _splashColor,
            child: Center(
              child: Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const Positioned(left: 0, right: 0, top: 0, height: _statusBar, child: _StatusBar(color: ink)),
        if (t < 1) Positioned.fill(child: _Launching(t: t)),
        // La isla dinámica, siempre encima.
        Positioned(
          top: 11,
          left: _screen.width / 2 - 62,
          child: Container(
            width: 124,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 15, 30, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '6:00',
            style: TextStyle(
              fontFamily: DeckFonts.sans,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(),
          Icon(Icons.signal_cellular_alt, size: 18, color: color),
          const SizedBox(width: 5),
          Icon(Icons.wifi, size: 18, color: color),
          const SizedBox(width: 5),
          Icon(Icons.battery_full, size: 18, color: color),
        ],
      ),
    );
  }
}

/// El arranque, como en iOS: el ícono crece desde su lugar hasta llenar la
/// pantalla con el splash. Al final, la app de verdad queda encima.
class _Launching extends StatelessWidget {
  const _Launching({required this.t});

  final double t;

  static final _iconRect = _HomeScreen.iconRect(5);

  @override
  Widget build(BuildContext context) {
    final grow = Motion.out.transform((t / 0.4).clamp(0, 1));
    final fade = 1 - Motion.inOut.transform(((t - 0.72) / 0.28).clamp(0, 1));
    final rect = Rect.lerp(_iconRect, Offset.zero & _screen, grow)!;
    return Stack(
      children: [
        if (grow < 1) const Positioned.fill(child: _HomeScreen()),
        if (t > 0)
          Positioned.fromRect(
            rect: rect,
            child: Opacity(
              opacity: fade,
              child: Container(
                decoration: BoxDecoration(
                  color: _splashColor,
                  borderRadius: BorderRadius.circular(14 + 40 * grow),
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
  static const _top = 84.0;
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
            left: 0,
            right: 0,
            top: 0,
            height: _statusBar,
            child: _StatusBar(color: Color(0xFFFFFFFF)),
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
          // La barra de inicio también está en la pantalla de inicio.
          Positioned(
            left: _screen.width / 2 - 67,
            bottom: 8,
            child: Container(
              width: 134,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El splash de EcoEats: lo que se ve mientras la app de verdad aparece.
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
