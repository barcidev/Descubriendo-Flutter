import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:servidor/sala.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Más que esto no cabe en un auditorio: el resto recibe un 503.
const _maximoConexiones = 1500;

Future<void> main() async {
  final puerto = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final token = Platform.environment['PRESENTER_TOKEN'] ?? 'ensayo';
  if (!Platform.environment.containsKey('PRESENTER_TOKEN')) {
    stdout.writeln('Aviso: sin PRESENTER_TOKEN, el token del presentador es «ensayo».');
  }

  final sala = Sala();
  var abiertas = 0;
  Timer.periodic(const Duration(milliseconds: 200), (_) => sala.tick());

  FutureOr<Response> socket(Request request) {
    final query = request.url.queryParameters;
    final presentador = query['rol'] == 'presentador';
    if (presentador && query['token'] != token) {
      return Response.forbidden('Token del presentador inválido');
    }
    if (abiertas >= _maximoConexiones) {
      return Response(503, body: 'Sala llena');
    }
    final handler = webSocketHandler((WebSocketChannel canal, String? _) {
      abiertas++;
      final conexion = Conexion(enviar: canal.sink.add, presentador: presentador);
      sala.entrar(conexion);
      if (presentador) stdout.writeln('Presentador conectado');
      void cerrar() {
        abiertas--;
        sala.salir(conexion);
        if (presentador) stdout.writeln('Presentador desconectado');
      }

      canal.stream.listen(
        (mensaje) {
          if (mensaje is String && mensaje.length <= 2000) {
            sala.recibir(conexion, mensaje);
          }
        },
        onDone: cerrar,
        onError: (Object _) {},
        cancelOnError: false,
      );
    }, pingInterval: const Duration(seconds: 20));
    return handler(request);
  }

  final publico = createStaticHandler(
    'public',
    defaultDocument: 'index.html',
  );
  final deck = File('deck_web/index.html').existsSync()
      ? createStaticHandler('deck_web', defaultDocument: 'index.html')
      : null;

  FutureOr<Response> rutas(Request request) {
    final ruta = request.url.path;
    switch (ruta) {
      case 'ws':
        return socket(request);
      case 'health':
        return Response.ok('ok');
      case 'excusas':
        return Response.ok(
          jsonEncode(sala.excusasAprobadas()),
          headers: {
            'content-type': 'application/json; charset=utf-8',
            'access-control-allow-origin': '*',
            'cache-control': 'no-store',
          },
        );
      case 'moderar':
        return Response.found('/moderar/');
    }
    if (deck != null && (ruta == 'deck' || ruta.startsWith('deck/'))) {
      if (ruta == 'deck') return Response.found('/deck/');
      return deck(request.change(path: 'deck'));
    }
    return publico(request);
  }

  final handler = const Pipeline()
      .addMiddleware(_cabeceras)
      .addHandler(rutas);
  final servidor = await shelf_io.serve(handler, InternetAddress.anyIPv4, puerto);
  servidor.autoCompress = true;
  stdout.writeln('Servidor listo en http://localhost:${servidor.port}');
}

/// Nada se cachea por mucho tiempo (la página cambia durante la charla) y
/// el navegador no adivina tipos de archivo.
Handler _cabeceras(Handler interno) => (request) async {
  final respuesta = await interno(request);
  if (request.url.path == 'ws') return respuesta;
  return respuesta.change(
    headers: {
      'x-content-type-options': 'nosniff',
      'referrer-policy': 'no-referrer',
      if (!respuesta.headers.containsKey('cache-control'))
        'cache-control': 'no-cache',
    },
  );
};
