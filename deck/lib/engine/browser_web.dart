import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Rect;
import 'package:web/web.dart' as web;

import 'browser.dart';

// Uno solo por pestaña: es quien escucha los cambios de pantalla completa.
final _browser = _WebBrowser();

Browser createBrowser() => _browser;

class _WebBrowser implements Browser {
  _WebBrowser() {
    web.document.onfullscreenchange = ((web.Event _) {
      _fullscreen.value = web.document.fullscreenElement != null;
    }).toJS;
  }

  final _fullscreen = ValueNotifier(web.document.fullscreenElement != null);

  @override
  ValueListenable<bool> get fullscreen => _fullscreen;

  @override
  Uri get uri => Uri.parse(web.window.location.href);

  @override
  void replaceHash(String hash) =>
      web.window.history.replaceState(null, '', '#$hash');

  @override
  void toggleFullscreen() {
    final document = web.document;
    if (document.fullscreenElement == null) {
      document.documentElement?.requestFullscreen();
    } else {
      document.exitFullscreen();
    }
  }

  // El almacenamiento puede estar bloqueado (ventana privada): se ignora.
  @override
  String? read(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } on Object {
      return null;
    }
  }

  @override
  void write(String key, String value) {
    try {
      web.window.localStorage.setItem(key, value);
    } on Object {
      // Sin almacenamiento la charla sigue funcionando.
    }
  }

  @override
  void openWindow(String url, String name) =>
      web.window.open(url, name, 'width=1440,height=900');

  @override
  Future<bool> showDemoApps() async {
    try {
      final response = await web.window
          .fetch('/mac/demo'.toJS, web.RequestInit(method: 'POST'))
          .toDart;
      if (response.status == 204) return true;
    } on Object {
      // Sin servidor local: se cambia de app a mano.
    }
    if (web.document.fullscreenElement != null) web.document.exitFullscreen();
    return false;
  }

  @override
  MessageChannel channel(String name) => _WebChannel(name);

  // La demo: un iframe fuera de Flutter, encima de la charla. Se carga una
  // sola vez y solo se mueve (mover un iframe en el DOM lo recarga).
  web.HTMLIFrameElement? _app;
  static const _appWidth = 390;
  bool _appHidden = true;

  /// Lo último que tuvo el foco en la charla, para devolvérselo si la app
  /// escondida se lo lleva al arrancar.
  web.HTMLElement? _lastFocus;

  void _keepFocus() {
    final frame = _app;
    if (frame == null || !_appHidden || web.document.activeElement != frame) return;
    frame.blur();
    _lastFocus?.focus();
  }

  @override
  void preloadApp(String path, {required VoidCallback onNext, required VoidCallback onPrevious}) {
    if (_app != null) return;
    final frame = web.document.createElement('iframe') as web.HTMLIFrameElement;
    frame
      ..src = '${web.window.location.origin}$path'
      ..title = 'Demo'
      // Escondida no puede quitarle el foco (ni el teclado) a la charla.
      ..inert = true;
    frame.style
      ..position = 'fixed'
      ..left = '-10000px'
      ..top = '0px'
      ..width = '${_appWidth}px'
      ..height = '772px'
      ..border = '0'
      ..zIndex = '10'
      ..backgroundColor = '#F4EEE4'
      // Las esquinas de abajo siguen la curva de la pantalla del iPhone.
      ..borderRadius = '0 0 34px 34px'
      ..transformOrigin = '0 0';
    web.document.addEventListener(
      'focusin',
      ((web.Event event) {
        final target = event.target;
        if (target != frame && target.isA<web.HTMLElement>()) {
          _lastFocus = target as web.HTMLElement;
        }
      }).toJS,
    );
    // Escondida, la app no se queda con el foco: el teclado y el control
    // remoto siguen siendo de la charla.
    frame.addEventListener('focus', ((web.Event _) => _keepFocus()).toJS);
    web.window.addEventListener('blur', ((web.Event _) => _keepFocus()).toJS);
    frame.onload = ((web.Event _) {
      _keepFocus();
      frame.contentWindow?.addEventListener(
        'keydown',
        ((web.KeyboardEvent event) {
          if (event.key == 'PageDown') onNext();
          if (event.key == 'PageUp') onPrevious();
        }).toJS,
      );
      // El mouse se vuelve un dedo: la app recibe toques, arrastres y
      // deslizamientos como en un celular.
      final document = frame.contentDocument;
      final script = document?.createElement('script');
      if (document != null && script != null) {
        script.textContent = _touchScript;
        document.head?.append(script);
      }
    }).toJS;
    web.document.body?.append(frame);
    _app = frame;
  }

  @override
  void placeApp(Rect? rect) {
    final frame = _app;
    if (frame == null) return;
    final style = frame.style;
    if (rect == null) {
      style.left = '-10000px';
      // Sin foco en la app, el teclado vuelve a la charla.
      _appHidden = true;
      frame.inert = true;
      if (web.document.activeElement == frame) frame.blur();
      return;
    }
    _appHidden = false;
    frame.inert = false;
    final scale = rect.width / _appWidth;
    style
      ..left = '${rect.left}px'
      ..top = '${rect.top}px'
      ..height = '${rect.height / scale}px'
      ..transform = 'scale($scale)';
  }
}

/// Corre dentro de la app de la demo: convierte el mouse en toques (con
/// arrastre, sin «hover») y le pone un cursor de dedo.
const _touchScript = r'''
(() => {
  let abajo = false;
  const dedo = (e, tipo, botones) => new PointerEvent(tipo, {
    bubbles: true, cancelable: true, composed: true,
    pointerId: e.pointerId, pointerType: 'touch', isPrimary: true,
    clientX: e.clientX, clientY: e.clientY, screenX: e.screenX, screenY: e.screenY,
    width: 22, height: 22, pressure: botones ? 0.5 : 0, buttons: botones,
    button: tipo === 'pointermove' ? -1 : 0,
  });
  const tocar = (tipo) => (e) => {
    if (!e.isTrusted || e.pointerType !== 'mouse') return;
    e.stopImmediatePropagation();
    if (tipo === 'pointerdown') {
      if (e.button !== 0) return;
      abajo = true;
    } else if (!abajo) {
      return;
    }
    if (tipo === 'pointerup' || tipo === 'pointercancel') abajo = false;
    e.target.dispatchEvent(dedo(e, tipo, tipo === 'pointerdown' || tipo === 'pointermove' ? 1 : 0));
  };
  for (const tipo of ['pointerdown', 'pointermove', 'pointerup', 'pointercancel']) {
    window.addEventListener(tipo, tocar(tipo), { capture: true });
  }
  const estilo = document.createElement('style');
  estilo.textContent = '*{cursor:url("data:image/svg+xml,' +
    encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30">' +
      '<circle cx="15" cy="15" r="11" fill="rgba(255,255,255,0.35)" stroke="rgba(20,20,20,0.45)" stroke-width="2"/></svg>') +
    '") 15 15, pointer !important}';
  document.head.append(estilo);
})();
''';

class _WebChannel implements MessageChannel {
  _WebChannel(String name) : _channel = web.BroadcastChannel(name) {
    _channel.onmessage = ((web.MessageEvent event) {
      final data = event.data;
      if (data != null && data.isA<JSString>()) {
        _messages.add((data as JSString).toDart);
      }
    }).toJS;
  }

  final web.BroadcastChannel _channel;
  final _messages = StreamController<String>.broadcast();

  @override
  Stream<String> get messages => _messages.stream;

  @override
  void post(String message) => _channel.postMessage(message.toJS);

  @override
  void close() {
    _channel.close();
    unawaited(_messages.close());
  }
}
