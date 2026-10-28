// Un auditorio de mentira para ensayar sin público y para probar la carga:
//
//   dart run tool/simular_audiencia.dart --url ws://localhost:8080/ws --clientes 150
//
// Cada cliente entra, vota cuando hay votación, aprieta el contador, manda
// alguna excusa o pregunta y califica al final, con ritmos al azar.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const _excusas = [
  'En mi máquina sí funciona.',
  'Seguro es un tema de caché.',
  'El cliente no actualizó la app.',
  'Eso estaba así cuando llegué.',
];

const _nombres = [
  'Valentina', 'Andrés', 'Camila', 'Santiago', 'Daniela', 'Sebastián',
  'María José', 'Juan David', 'Laura', 'Carlos', 'Mariana', 'Alejandro',
];

const _preguntas = [
  '¿Flutter sirve para hacer apps web grandes?',
  '¿Qué tan difícil es pasar de Kotlin a Dart?',
  '¿Cómo manejan el estado en apps grandes?',
  '¿Se puede usar Flutter dentro de una app nativa existente?',
];

Future<void> main(List<String> argumentos) async {
  String valor(String nombre, String defecto) {
    final indice = argumentos.indexOf(nombre);
    return indice >= 0 && indice + 1 < argumentos.length
        ? argumentos[indice + 1]
        : defecto;
  }

  final url = valor('--url', 'ws://localhost:8080/ws');
  final cantidad = int.parse(valor('--clientes', '60'));
  final azar = math.Random();
  var conectados = 0;

  for (var i = 0; i < cantidad; i++) {
    unawaited(_cliente(url, i, azar).then((_) => conectados--));
    conectados++;
    // Entran de a poquitos, como una sala que se va llenando.
    await Future<void>.delayed(Duration(milliseconds: 20 + azar.nextInt(60)));
  }
  stdout.writeln('$conectados clientes simulados en $url. Ctrl+C para salir.');
}

Future<void> _cliente(String url, int numero, math.Random azar) async {
  final WebSocket socket;
  try {
    socket = await WebSocket.connect(url);
  } on Object catch (error) {
    stderr.writeln('Cliente $numero no pudo entrar: $error');
    return;
  }
  void enviar(Map<String, Object?> mensaje) => socket.add(jsonEncode(mensaje));
  enviar({'t': 'hola', 'id': 'simulado-${numero.toString().padLeft(5, '0')}'});
  // Como en la sala: primero el nombre, después todo lo demás.
  enviar({'t': 'nombre', 'nombre': '${_nombres[numero % _nombres.length]} ${numero + 1}'});

  Map<String, Object?> cue = const {'mode': 'idle'};
  Map<String, Object?> concurso = const {};
  final votadas = <String>{};
  final respondidas = <int>{};
  var escribio = false;
  var califico = false;

  final ritmo = Timer.periodic(Duration(milliseconds: 400 + azar.nextInt(500)), (_) {
    switch (cue['mode']) {
      case 'poll':
        final poll = cue['poll']! as Map;
        final id = poll['id']! as String;
        if (cue['open'] == true && !votadas.contains(id) && azar.nextDouble() < 0.35) {
          final opciones = [for (final o in poll['options']! as List) (o as Map)['id']];
          final elegidas = poll['multiple'] == true
              ? opciones.where((_) => azar.nextDouble() < 0.45).toList()
              : [opciones[math.min(azar.nextInt(opciones.length), azar.nextInt(opciones.length))]];
          enviar({'t': 'voto', 'poll': id, 'opciones': elegidas});
          votadas.add(id);
        }
      case 'counter':
        enviar({'t': 'toque', 'n': 1 + azar.nextInt(6)});
      case 'excuse':
        if (!escribio && azar.nextDouble() < 0.2) {
          escribio = true;
          enviar({'t': 'excusa', 'texto': _excusas[azar.nextInt(_excusas.length)]});
        }
      case 'quiz':
        // Cada quien responde a su ritmo; unos aciertan, otros no.
        final indice = concurso['index'];
        final opciones = concurso['options'];
        if (concurso['phase'] == 'pregunta' &&
            indice is int &&
            opciones is List &&
            !respondidas.contains(indice) &&
            azar.nextDouble() < 0.12) {
          respondidas.add(indice);
          enviar({'t': 'respuesta', 'index': indice, 'opcion': azar.nextInt(opciones.length)});
        }
      case 'rating':
        if (!califico && azar.nextDouble() < 0.3) {
          califico = true;
          enviar({'t': 'estrellas', 'n': 3 + azar.nextInt(3)});
        }
      default:
        // Las preguntas se escriben en cualquier momento de la charla.
        if (azar.nextDouble() < 0.004) {
          enviar({'t': 'pregunta', 'texto': _preguntas[azar.nextInt(_preguntas.length)]});
        }
    }
    if (azar.nextDouble() < 0.04) {
      enviar({'t': 'reaccion', 'r': ['fuego', 'bug', 'aplauso'][azar.nextInt(3)]});
    }
  });

  await for (final mensaje in socket) {
    if (mensaje is! String) continue;
    final json = jsonDecode(mensaje) as Map<String, Object?>;
    if (json['t'] == 'estado') {
      cue = json['cue']! as Map<String, Object?>;
      concurso = (json['quiz'] as Map<String, Object?>?) ?? const {};
    }
  }
  ritmo.cancel();
}
