import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:servidor/jurado.dart';
import 'package:servidor/llave.dart';
import 'package:servidor/proxy.dart';
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
  // Sin clave no hay modo presentador: nada de claves por defecto.
  final llave = Llave(Platform.environment['PRESENTER_TOKEN']);
  if (!llave.configurada) {
    stdout.writeln(
        'Aviso: sin PRESENTER_TOKEN nadie puede entrar como presentador.');
  }
  // El guion no es un archivo público: solo lo recibe quien entra con la clave.
  final archivoGuion = File('privado/guion.md');
  final guion =
      archivoGuion.existsSync() ? archivoGuion.readAsStringSync() : '';

  // Gemini escoge las excusas y las preguntas. Sin clave, el plan B.
  final claveGemini = Platform.environment['GEMINI_API_KEY'] ?? '';
  final jurado = claveGemini.isEmpty
      ? null
      : Gemini(
          claveGemini,
          modelo: Platform.environment['GEMINI_MODEL'] ?? 'gemini-flash-latest',
        );
  if (jurado == null) {
    stdout.writeln('Aviso: sin GEMINI_API_KEY las excusas se eligen sin IA.');
  }
  final sala = Sala(jurado: jurado);
  // La API en Kotlin de la demo, vista desde este mismo origen.
  final ecoeats = reenviarA(Uri.parse(
    Platform.environment['ECOEATS_API'] ??
        'https://ecoeats-api-kotlin-production.up.railway.app',
  ));
  var abiertas = 0;
  Timer.periodic(const Duration(milliseconds: 200), (_) => sala.tick());

  FutureOr<Response> socket(Request request) {
    if (abiertas >= _maximoConexiones) {
      return Response(503, body: 'Sala llena');
    }
    final origen = _origen(request);
    final handler = webSocketHandler((WebSocketChannel canal, String? _) {
      abiertas++;
      final conexion = Conexion(enviar: canal.sink.add, presentador: false);
      sala.entrar(conexion);

      void conceder(Map<String, Object?> respuesta) {
        sala.promover(conexion);
        conexion
          ..enviar(jsonEncode(respuesta))
          ..enviar(jsonEncode({'t': 'guion', 'texto': guion}));
        stdout.writeln('Presentador conectado');
      }

      // La clave (o una sesión de antes) llega en un mensaje, nunca en la URL.
      void acceder(Map<String, Object?> mensaje) {
        if (mensaje['t'] == 'auth') {
          if (llave.sesionValida(mensaje['sesion'])) {
            conceder({'t': 'acceso', 'ok': true});
          } else {
            conexion.enviar(jsonEncode({'t': 'acceso', 'error': 'sesion'}));
          }
          return;
        }
        switch (llave.entrar(mensaje['token'], origen: origen)) {
          case Concedido(:final sesion, :final expira):
            conceder({
              't': 'acceso',
              'ok': true,
              'sesion': sesion,
              'expira': expira.toUtc().toIso8601String(),
            });
          case Denegado(:final restantes, :final sinClave):
            conexion.enviar(jsonEncode({
              't': 'acceso',
              'error': sinClave ? 'sin-clave' : 'clave',
              'restantes': restantes,
            }));
          case Bloqueado(:final espera):
            stdout.writeln('Intentos de clave bloqueados para $origen');
            conexion.enviar(jsonEncode({
              't': 'acceso',
              'error': 'bloqueado',
              'espera': espera.inSeconds,
            }));
        }
      }

      void cerrar() {
        abiertas--;
        sala.salir(conexion);
        if (conexion.presentador) stdout.writeln('Presentador desconectado');
      }

      canal.stream.listen(
        (mensaje) {
          if (mensaje is! String || mensaje.length > 2000) return;
          if (!conexion.presentador &&
              (mensaje.contains('"login"') || mensaje.contains('"auth"'))) {
            final json = _json(mensaje);
            if (json != null && (json['t'] == 'login' || json['t'] == 'auth')) {
              acceder(json);
              return;
            }
          }
          sala.recibir(conexion, mensaje);
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
  // EcoEats para web: la demo que corre dentro de la charla.
  final ecoeatsWeb = File('ecoeats_web/index.html').existsSync()
      ? createStaticHandler('ecoeats_web', defaultDocument: 'index.html')
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
          jsonEncode(sala.excusasElegidas()),
          headers: {
            'content-type': 'application/json; charset=utf-8',
            'access-control-allow-origin': '*',
            'cache-control': 'no-store',
          },
        );
      case 'moderar':
        return Response.found('/moderar/');
    }
    if (ruta.startsWith('ecoeats-api/')) {
      return ecoeats(request.change(path: 'ecoeats-api'));
    }
    if (ecoeatsWeb != null &&
        (ruta == 'ecoeats' || ruta.startsWith('ecoeats/'))) {
      if (ruta == 'ecoeats') return Response.found('/ecoeats/');
      return ecoeatsWeb(request.change(path: 'ecoeats'));
    }
    if (deck != null && (ruta == 'deck' || ruta.startsWith('deck/'))) {
      if (ruta == 'deck') return Response.found('/deck/');
      return deck(request.change(path: 'deck'));
    }
    return publico(request);
  }

  final handler = const Pipeline().addMiddleware(_cabeceras).addHandler(rutas);
  final servidor =
      await shelf_io.serve(handler, InternetAddress.anyIPv4, puerto);
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

/// Quién escribe la clave: detrás del proxy de Render, la IP real viene en
/// x-forwarded-for.
String _origen(Request request) {
  final reenviada = request.headers['x-forwarded-for'];
  if (reenviada != null && reenviada.isNotEmpty)
    return reenviada.split(',').first.trim();
  final conexion = request.context['shelf.io.connection_info'];
  return conexion is HttpConnectionInfo
      ? conexion.remoteAddress.address
      : 'desconocido';
}

Map<String, Object?>? _json(String mensaje) {
  try {
    final json = jsonDecode(mensaje);
    return json is Map<String, Object?> ? json : null;
  } on FormatException {
    return null;
  }
}
