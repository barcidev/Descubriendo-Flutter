// El servidor local para presentar desde el portátil: sirve la charla en
// http://127.0.0.1:8090, EcoEats web en /ecoeats/ y su API reenviada en
// /ecoeats-api/, igual que el servidor de Render. Además le deja a la charla
// una orden para el final: mostrar el IDE y el simulador del Mac.
//
//   cd servidor && fvm dart run tool/presentar.dart ../deck/build/web
//
// Las apps que se traen al frente salen de DEMO_APPS (separadas por coma),
// por omisión el simulador de iOS.
import 'dart:io';

import 'package:servidor/proxy.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

Future<void> main(List<String> args) async {
  final web = args.isNotEmpty ? args.first : '../deck/build/web';
  if (!File('$web/index.html').existsSync()) {
    stderr.writeln('No encuentro la charla compilada en $web');
    exit(1);
  }
  final charla = createStaticHandler(web, defaultDocument: 'index.html');
  final ecoeatsWeb = File('ecoeats_web/index.html').existsSync()
      ? createStaticHandler('ecoeats_web', defaultDocument: 'index.html')
      : null;
  final api = reenviarA(Uri.parse(
    Platform.environment['ECOEATS_API'] ??
        'https://ecoeats-api-kotlin-production.up.railway.app',
  ));
  final apps = (Platform.environment['DEMO_APPS'] ?? 'Simulator')
      .split(',')
      .map((app) => app.trim())
      .where((app) => app.isNotEmpty)
      .toList();

  Future<Response> rutas(Request request) async {
    final ruta = request.url.path;
    if (ruta == 'mac/demo' && request.method == 'POST') {
      // La charla terminó sus créditos: al frente el IDE y el simulador.
      for (final app in apps) {
        await Process.run('open', ['-a', app]);
      }
      return Response(204);
    }
    if (ruta.startsWith('ecoeats-api/')) {
      return await api(request.change(path: 'ecoeats-api'));
    }
    if (ecoeatsWeb != null &&
        (ruta == 'ecoeats' || ruta.startsWith('ecoeats/'))) {
      if (ruta == 'ecoeats') return Response.found('/ecoeats/');
      return await ecoeatsWeb(request.change(path: 'ecoeats'));
    }
    return await charla(request);
  }

  final servidor = await shelf_io.serve(
    const Pipeline().addHandler(rutas),
    InternetAddress.loopbackIPv4,
    int.tryParse(Platform.environment['PUERTO'] ?? '') ?? 8090,
  );
  stdout.writeln('Charla en http://127.0.0.1:${servidor.port} · Ctrl+C para cerrar');
}
