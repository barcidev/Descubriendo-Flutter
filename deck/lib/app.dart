import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'engine/browser.dart';
import 'engine/deck_controller.dart';
import 'engine/deck_scope.dart';
import 'engine/deck_shell.dart';
import 'engine/slide.dart';
import 'live/live_config.dart';
import 'live/live_controller.dart';
import 'slides/slides.dart';
import 'theme/deck_theme.dart';
import 'theme/tokens.dart';

class DeckApp extends StatefulWidget {
  const DeckApp({required this.browser, this.slides, super.key});

  final Browser browser;

  /// Para los tests: una charla más corta.
  final List<Slide>? slides;

  @override
  State<DeckApp> createState() => _DeckAppState();
}

class _DeckAppState extends State<DeckApp> {
  late final DeckController _deck;
  late final _live = LiveController(
    config: LiveConfig.resolve(widget.browser),
    browser: widget.browser,
  )..start();
  late bool _night;
  StreamSubscription<String>? _remote;

  @override
  void initState() {
    super.initState();
    // La URL dice dónde íbamos: recargar no te devuelve a la portada.
    final start = DeckController.parseHash(widget.browser.uri.fragment);
    _deck = DeckController(
      widget.slides ?? buildDeck(),
      index: start?.$1 ?? 0,
      step: start?.$2 ?? 0,
    )..addListener(_sync);
    _night = _deck.night;
    // El celular del presentador también pasa diapositivas.
    _remote = _live.navigation.listen(
      (direction) => direction == 'next' ? _deck.next() : _deck.previous(),
    );
    _sync();
  }

  void _sync() {
    widget.browser.replaceHash(_deck.hash);
    _live
      ..setCue(_deck.slide.cueAt(_deck.step))
      ..setSlide(
        id: _deck.slide.id,
        title: _deck.slide.title,
        index: _deck.index + 1,
        total: _deck.slides.length,
        step: _deck.step + 1,
        steps: _deck.slide.steps,
      );
    if (_deck.night != _night) setState(() => _night = _deck.night);
  }

  @override
  void dispose() {
    unawaited(_remote?.cancel());
    _deck
      ..removeListener(_sync)
      ..dispose();
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Descubriendo Flutter',
      debugShowCheckedModeBanner: false,
      // El cambio de tema se interpola: ThemeData.lerp, también en la charla.
      theme: deckTheme(_night ? DeckColors.night : DeckColors.day),
      themeAnimationDuration: Motion.slow,
      themeAnimationCurve: Motion.inOut,
      home: DeckScope(
        deck: _deck,
        live: _live,
        browser: widget.browser,
        child: DeckShell(deck: _deck, live: _live, browser: widget.browser),
      ),
    );
  }
}
