import '../config.dart';
import '../engine/browser.dart';

/// Dónde está el servidor de votaciones y con qué token se entra.
///
/// Se resuelve al abrir la charla, sin recompilar:
///   1. `?servidor=https://…&token=…` en la URL (y se recuerda),
///   2. lo que se recordó la vez pasada,
///   3. `--dart-define=SERVIDOR=…`,
///   4. el mismo origen, si el servidor sirve la charla en `/deck/`.
/// `?servidor=` vacío olvida el servidor: modo mano alzada.
class LiveConfig {
  const LiveConfig({this.server, this.token});

  final Uri? server;
  final String? token;

  bool get enabled => server != null;

  /// La página del público: la raíz del servidor.
  String get joinUrl => server == null
      ? ''
      : Uri(
          scheme: server!.scheme,
          host: server!.host,
          port: server!.hasPort ? server!.port : null,
        ).toString();

  Uri? get socket => server == null
      ? null
      : Uri(
          scheme: server!.scheme == 'https' ? 'wss' : 'ws',
          host: server!.host,
          port: server!.hasPort ? server!.port : null,
          path: '/ws',
          queryParameters: {'rol': 'presentador', 'token': ?token},
        );

  Uri? get excuses => server?.replace(path: '/excusas', query: '');

  static const _serverKey = 'charla.servidor';
  static const _tokenKey = 'charla.token';

  static LiveConfig resolve(Browser browser) {
    final uri = browser.uri;
    final query = uri.queryParameters;
    if (query.containsKey('servidor')) browser.write(_serverKey, query['servidor']!);
    if (query['token'] case final token? when token.isNotEmpty) {
      browser.write(_tokenKey, token);
    }
    final stored = browser.read(_serverKey);
    final address = query['servidor'] ??
        stored ??
        (Config.server.isEmpty ? null : Config.server);
    Uri? server = address == null || address.isEmpty ? null : Uri.tryParse(address);
    if (server != null && !server.hasScheme) server = null;
    if (server == null && stored == null && uri.path.startsWith('/deck')) {
      server = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
      );
    }
    return LiveConfig(server: server, token: browser.read(_tokenKey));
  }
}
