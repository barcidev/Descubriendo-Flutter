import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'browser.dart';

Browser createBrowser() => _WebBrowser();

class _WebBrowser implements Browser {
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
  MessageChannel channel(String name) => _WebChannel(name);
}

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
