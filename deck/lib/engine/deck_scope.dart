import 'package:flutter/widgets.dart';

import '../live/live_controller.dart';
import 'browser.dart';
import 'deck_controller.dart';

/// Lo que cualquier diapositiva puede pedir: la navegación, la conexión con
/// el público y el navegador.
class DeckScope extends InheritedWidget {
  const DeckScope({
    required this.deck,
    required this.live,
    required this.browser,
    required super.child,
    super.key,
  });

  final DeckController deck;
  final LiveController live;
  final Browser browser;

  static DeckScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DeckScope>();
    assert(scope != null, 'No hay DeckScope arriba de este widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(DeckScope oldWidget) =>
      deck != oldWidget.deck ||
      live != oldWidget.live ||
      browser != oldWidget.browser;
}
