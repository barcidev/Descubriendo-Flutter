import 'dart:io';

import 'package:shelf/shelf.dart';

/// Reenvía peticiones a otra API, como si vinieran de este mismo servidor.
///
/// La demo de EcoEats corre en la charla como app web, y su API en Kotlin
/// no acepta llamadas de otros orígenes (CORS). Desde el mismo origen no
/// hay CORS: el navegador le habla a este servidor y este a la API.
Handler reenviarA(Uri destino) {
  final cliente = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 30);
  // Cabeceras que son de esta conexión, no de la petición. Sin Origin, la
  // API no aplica CORS; sin Accept-Encoding, responde sin comprimir.
  const pedidoSinCopiar = {
    'host',
    'connection',
    'content-length',
    'transfer-encoding',
    'origin',
    'referer',
    'cookie',
    'accept-encoding',
  };
  const respuestaSinCopiar = {
    'connection',
    'content-length',
    'content-encoding',
    'transfer-encoding',
    'keep-alive',
    'strict-transport-security',
  };
  return (request) async {
    final uri = destino.replace(
      path: '${destino.path}/${request.url.path}'.replaceAll('//', '/'),
      query: request.url.query.isEmpty ? null : request.url.query,
    );
    try {
      final pedido = await cliente.openUrl(request.method, uri);
      request.headers.forEach((nombre, valor) {
        if (!pedidoSinCopiar.contains(nombre.toLowerCase())) {
          pedido.headers.set(nombre, valor);
        }
      });
      final cuerpo = await request.read().fold<List<int>>(
        <int>[],
        (bytes, parte) => bytes..addAll(parte),
      );
      if (cuerpo.isNotEmpty) {
        pedido.contentLength = cuerpo.length;
        pedido.add(cuerpo);
      }
      final respuesta =
          await pedido.close().timeout(const Duration(seconds: 30));
      final cabeceras = <String, String>{};
      respuesta.headers.forEach((nombre, valores) {
        if (!respuestaSinCopiar.contains(nombre.toLowerCase())) {
          cabeceras[nombre] = valores.join(', ');
        }
      });
      return Response(respuesta.statusCode,
          body: respuesta, headers: cabeceras);
    } on Object catch (error) {
      return Response(502, body: 'La API no respondió: $error');
    }
  };
}
