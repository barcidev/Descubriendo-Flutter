import 'package:flutter/foundation.dart';

import 'browser_stub.dart' if (dart.library.js_interop) 'browser_web.dart'
    as platform;

/// Lo poco que la charla le pide al navegador: la URL, pantalla completa,
/// almacenamiento local y un canal entre ventanas (la del presentador).
///
/// En los tests corre la versión vacía, que no toca nada.
abstract interface class Browser {
  static Browser get current => platform.createBrowser();

  Uri get uri;

  /// Reemplaza el `#…` de la URL sin agregar entradas al historial.
  void replaceHash(String hash);

  void toggleFullscreen();

  /// Si la charla está en pantalla completa. Cambia también cuando se sale
  /// con Esc, sin pasar por la charla.
  ValueListenable<bool> get fullscreen;

  String? read(String key);

  void write(String key, String value);

  void openWindow(String url, String name);

  /// Al final de los créditos: le pide al servidor local (presentar.sh) que
  /// traiga al frente el IDE y el simulador del Mac. Si no hay servidor
  /// local, sale de pantalla completa para cambiar de app a mano.
  Future<bool> showDemoApps();

  MessageChannel channel(String name);
}

/// Mensajes de texto entre pestañas del mismo origen (BroadcastChannel).
abstract interface class MessageChannel {
  Stream<String> get messages;

  void post(String message);

  void close();
}
