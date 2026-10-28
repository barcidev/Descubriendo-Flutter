import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'engine/browser.dart';

void main() {
  // El `#/12/2` de la URL lo maneja la charla (dónde íbamos); si Flutter
  // también lo usara para sus rutas, al recargar se volvería a la portada.
  setUrlStrategy(null);
  runApp(DeckApp(browser: Browser.current));
}
