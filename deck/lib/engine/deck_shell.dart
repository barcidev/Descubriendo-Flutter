import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../live/join_card.dart';
import '../live/live_controller.dart';
import '../live/presenter_login.dart';
import '../live/reactions_layer.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import 'browser.dart';
import 'deck_controller.dart';
import 'overview.dart';
import 'slide_host.dart';
import 'stage.dart';
import 'status_bar.dart';

/// Todo lo que hay en pantalla y el teclado que lo maneja.
///
/// Las teclas se atienden antes que cualquier botón de las demos, para que
/// el control remoto (flechas, PgUp/PgDn, espacio) siempre pase de
/// diapositiva.
class DeckShell extends StatefulWidget {
  const DeckShell({
    required this.deck,
    required this.live,
    required this.browser,
    super.key,
  });

  final DeckController deck;
  final LiveController live;
  final Browser browser;

  @override
  State<DeckShell> createState() => _DeckShellState();
}

class _DeckShellState extends State<DeckShell> {
  // Lo que mandan los controles remotos: flechas, PgUp/PgDn y espacio.
  static final _forward = {
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.pageDown,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };
  static final _backward = {
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.pageUp,
    LogicalKeyboardKey.backspace,
  };

  /// Lo que se va escribiendo después de oprimir G («ir a…»).
  String? _goTo;

  DeckController get _deck => widget.deck;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _typing() =>
      FocusManager.instance.primaryFocus?.context?.widget is EditableText;

  bool get _loggingIn => const {
    PresenterAccess.login,
    PresenterAccess.checking,
  }.contains(widget.live.access);

  bool _onKey(KeyEvent event) {
    // Mientras se pide el token, el teclado es del formulario.
    if (event is KeyUpEvent || _typing() || _loggingIn) return false;
    final key = event.logicalKey;
    final repeat = event is KeyRepeatEvent;

    if (_goTo != null) return _onGoToKey(key, event.character);

    if (_deck.overview && !repeat) {
      if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyO) {
        _deck.toggleOverview();
        return true;
      }
    }

    if (_forward.contains(key)) {
      _deck.next();
      return true;
    }
    if (_backward.contains(key)) {
      _deck.previous();
      return true;
    }
    if (repeat) return false;

    switch (key) {
      case LogicalKeyboardKey.home:
        _deck.goTo(0);
      case LogicalKeyboardKey.end:
        _deck.goTo(_deck.slides.length - 1);
      case LogicalKeyboardKey.keyX:
        _deck.toggleXray();
      case LogicalKeyboardKey.keyT:
        _deck.toggleTheme();
      case LogicalKeyboardKey.keyF:
        widget.browser.toggleFullscreen();
      case LogicalKeyboardKey.keyB || LogicalKeyboardKey.period:
        _deck.togglePause();
      case LogicalKeyboardKey.keyO:
        _deck.toggleOverview();
      case LogicalKeyboardKey.keyS:
        widget.live.toggleSimulation();
      case LogicalKeyboardKey.keyQ:
        _deck.toggleQr();
      case LogicalKeyboardKey.keyR:
        _deck.toggleReactions();
      case LogicalKeyboardKey.keyL:
        widget.live.logout();
      case LogicalKeyboardKey.keyG:
        setState(() => _goTo = '');
      case LogicalKeyboardKey.escape:
        if (_deck.paused) _deck.togglePause();
        if (_deck.xray) _deck.toggleXray();
        if (_deck.qr) _deck.toggleQr();
      default:
        return _onDigit(key);
    }
    return true;
  }

  /// Mano alzada: en una votación, 1–9 suman un voto a esa opción y con
  /// Shift lo restan.
  bool _onDigit(LogicalKeyboardKey key) {
    const digits = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    final number = digits.indexOf(key);
    final poll = widget.live.cue.poll;
    if (number < 0 || poll == null || number >= poll.options.length) {
      return false;
    }
    final delta = HardwareKeyboard.instance.isShiftPressed ? -1 : 1;
    widget.live.raiseHands(poll.id, poll.options[number].id, delta);
    return true;
  }

  bool _onGoToKey(LogicalKeyboardKey key, String? character) {
    final typed = _goTo!;
    if (key == LogicalKeyboardKey.escape) {
      setState(() => _goTo = null);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final number = int.tryParse(typed);
      setState(() => _goTo = null);
      if (number != null) _deck.goTo(number - 1);
    } else if (key == LogicalKeyboardKey.backspace) {
      if (typed.isNotEmpty) {
        setState(() => _goTo = typed.substring(0, typed.length - 1));
      }
    } else if (character != null && RegExp(r'^\d$').hasMatch(character)) {
      if (typed.length < 3) setState(() => _goTo = typed + character);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Stage(
      child: ListenableBuilder(
        listenable: Listenable.merge([_deck, widget.live]),
        builder: (context, _) {
          final colors = context.colors;
          return DefaultTextStyle(
            style: DeckType.body.copyWith(color: colors.ink),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SlideHost(deck: _deck),
                if (_deck.reactions) ReactionsLayer(live: widget.live),
                if (_deck.slide.chrome)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: StatusBar(
                      deck: _deck,
                      live: widget.live,
                      browser: widget.browser,
                    ),
                  ),
                if (_deck.qr) const QrOverlay(),
                if (_deck.overview) Overview(deck: _deck),
                if (_goTo != null) _GoToBox(typed: _goTo!, total: _deck.slides.length),
                if (_deck.paused) const _Curtain(),
                AnimatedSwitcher(
                  duration: Motion.base,
                  child: _loggingIn
                      ? PresenterLogin(live: widget.live, browser: widget.browser)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GoToBox extends StatelessWidget {
  const _GoToBox({required this.typed, required this.total});

  final String typed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: colors.accent, width: 2),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'ir a ', style: TextStyle(color: colors.muted)),
              TextSpan(
                text: typed.isEmpty ? '_' : typed,
                style: TextStyle(color: colors.accentText),
              ),
              TextSpan(text: ' / $total', style: TextStyle(color: colors.faint)),
            ],
          ),
          style: DeckType.title.copyWith(fontFamily: DeckFonts.mono),
        ),
      ),
    );
  }
}

/// Pantalla negra para pausar sin que el público vea la siguiente.
class _Curtain extends StatelessWidget {
  const _Curtain();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF000000),
      child: Center(
        child: Text(
          '// pausa',
          style: TextStyle(
            fontFamily: DeckFonts.mono,
            fontSize: 20,
            color: Color(0xFF1C2A40),
          ),
        ),
      ),
    );
  }
}
