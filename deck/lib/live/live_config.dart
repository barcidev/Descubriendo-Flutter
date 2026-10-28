import '../config.dart';
import '../engine/browser.dart';

/// Dónde está el servidor de votaciones.
///
/// Se resuelve al abrir la charla, sin recompilar:
///   1. `?servidor=https://…` en la URL (y se recuerda),
///   2. lo que se recordó la vez pasada,
///   3. `--dart-define=SERVIDOR=…`,
///   4. el mismo origen, si el servidor sirve la charla en `/deck/`.
/// `?servidor=` vacío olvida el servidor: modo mano alzada.
///
/// El token del presentador no pasa por aquí: se escribe en la pantalla de
/// entrada y viaja dentro del WebSocket, nunca en la URL.
class LiveConfig {
  const LiveConfig({this.server});

  final Uri? server;

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
        );

  Uri? get excuses => server?.replace(path: '/excusas', query: '');

  static const _serverKey = 'charla.servidor';

  static LiveConfig resolve(Browser browser) {
    final uri = browser.uri;
    final query = uri.queryParameters;
    if (query.containsKey('servidor')) browser.write(_serverKey, query['servidor']!);
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
    return LiveConfig(server: server);
  }
}
