import 'browser.dart';

Browser createBrowser() => _NoBrowser();

class _NoBrowser implements Browser {
  final _storage = <String, String>{};

  @override
  Uri get uri => Uri();

  @override
  void replaceHash(String hash) {}

  @override
  void toggleFullscreen() {}

  @override
  String? read(String key) => _storage[key];

  @override
  void write(String key, String value) => _storage[key] = value;

  @override
  void openWindow(String url, String name) {}

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
