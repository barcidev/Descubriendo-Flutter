import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Rect;

import 'browser.dart';

final _browser = _NoBrowser();

Browser createBrowser() => _browser;

class _NoBrowser implements Browser {
  final _storage = <String, String>{};

  @override
  Uri get uri => Uri();

  @override
  void replaceHash(String hash) {}

  @override
  void toggleFullscreen() => _fullscreen.value = !_fullscreen.value;

  final _fullscreen = ValueNotifier(false);

  @override
  ValueListenable<bool> get fullscreen => _fullscreen;

  @override
  String? read(String key) => _storage[key];

  @override
  void write(String key, String value) => _storage[key] = value;

  @override
  void openWindow(String url, String name) {}

  @override
  Future<bool> showDemoApps() async => false;

  @override
  void preloadApp(String path, {required VoidCallback onNext, required VoidCallback onPrevious}) {}

  @override
  void placeApp(Rect? rect) {}

  @override
  MessageChannel channel(String name) => _NoChannel();
}

class _NoChannel implements MessageChannel {
  @override
  Stream<String> get messages => const Stream.empty();

  @override
  void post(String message) {}

  @override
  void close() {}
}
