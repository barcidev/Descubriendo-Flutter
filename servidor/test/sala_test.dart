import 'dart:convert';
import 'dart:math' as math;

import 'package:servidor/sala.dart';
import 'package:test/test.dart';

/// Un celular de mentira: guarda lo que el servidor le manda.
class _Celular {
  _Celular(this.sala, {this.presentador = false, DateTime Function()? reloj}) {
    conexion = Conexion(
      enviar: recibidos.add,
      presentador: presentador,
      reloj: reloj,
    );
    sala.entrar(conexion);
  }

  final Sala sala;
  final bool presentador;
  late final Conexion conexion;
  final recibidos = <String>[];

  void manda(Map<String, Object?> mensaje) =>
      sala.recibir(conexion, jsonEncode(mensaje));

  Map<String, Object?> get ultimoEstado => recibidos
      .map((m) => jsonDecode(m) as Map<String, Object?>)
      .lastWhere((m) => m['t'] == 'estado');
}

Map<String, Object?> _encuesta({bool multiple = false, bool open = true}) => {
  'mode': 'poll',
  'open': open,
  'revealed': false,
  'poll': {
    'id': 'quiz',
    'question': '¿Cuál?',
    'multiple': multiple,
    'options': [
      {'id': 'a', 'label': 'A'},
      {'id': 'b', 'label': 'B'},
    ],
  },
};

void main() {
  late Sala sala;
  late _Celular presentador;

  setUp(() {
    sala = Sala(azar: math.Random(1));
    presentador = _Celular(sala, presentador: true);
  });

  _Celular entra(String id) =>
      _Celular(sala)..manda({'t': 'hola', 'id': id});

  test('cada celular recibe un widget como identidad', () {
    final celular = entra('cliente-0001');
    final yo = jsonDecode(celular.recibidos.first) as Map<String, Object?>;
    expect(yo['t'], 'yo');
    expect(yo['widget'], isA<String>());
    expect(sala.conectados, 1);
  });

  test('un id inválido no entra', () {
    _Celular(sala).manda({'t': 'hola', 'id': 'x'});
    expect(sala.conectados, 0);
  });

  test('un voto por persona, aunque recargue la página', () {
    presentador.manda({'t': 'cue', 'cue': _encuesta()});
    final celular = entra('cliente-0001');
    celular.manda({'t': 'voto', 'poll': 'quiz', 'opciones': ['a']});
    // Recarga: misma persona, conexión nueva, vuelve a votar.
    sala.salir(celular.conexion);
    final otraVez = entra('cliente-0001');
    otraVez.manda({'t': 'voto', 'poll': 'quiz', 'opciones': ['b']});
    sala.tick();
    final resultados = presentador.ultimoEstado['polls']! as Map;
    expect(resultados['quiz'], {
      'counts': {'b': 1},
      'voters': 1,
    });
  });

  test('una encuesta de una sola opción ignora las demás', () {
    presentador.manda({'t': 'cue', 'cue': _encuesta()});
    entra('cliente-0001').manda({
      't': 'voto',
      'poll': 'quiz',
      'opciones': ['a', 'b', 'inventada'],
    });
    sala.tick();
    final quiz = (presentador.ultimoEstado['polls']! as Map)['quiz'] as Map;
    expect(quiz['counts'], {'a': 1});
  });

  test('con la votación cerrada no se aceptan votos', () {
    presentador.manda({'t': 'cue', 'cue': _encuesta(open: false)});
    entra('cliente-0001').manda({'t': 'voto', 'poll': 'quiz', 'opciones': ['a']});
    sala.tick();
    expect(presentador.ultimoEstado['polls'], isEmpty);
  });

  test('el contador tiene límite de ritmo por celular', () {
    var ahora = DateTime(2026, 10, 28, 18);
    presentador.manda({
      't': 'cue',
      'cue': {'mode': 'counter'},
    });
    final celular = _Celular(sala, reloj: () => ahora)
      ..manda({'t': 'hola', 'id': 'cliente-0001'});
    for (var i = 0; i < 10; i++) {
      celular.manda({'t': 'toque', 'n': 25});
    }
    // La cubeta empieza con 60 fichas: pasan dos tandas de 25.
    expect(sala.contador, 50);
    ahora = ahora.add(const Duration(seconds: 2));
    celular.manda({'t': 'toque', 'n': 25});
    expect(sala.contador, 75);
  });

  test('las excusas solo salen al aprobarlas', () {
    presentador.manda({
      't': 'cue',
      'cue': {'mode': 'excuse'},
    });
    final celular = entra('cliente-0001')
      ..manda({'t': 'excusa', 'texto': '  Es   culpa del caché  '});
    sala.tick();
    expect(celular.ultimoEstado['excuses'], isEmpty);
    final pendiente =
        (presentador.ultimoEstado['excuses']! as List).single as Map;
    expect(pendiente['text'], 'Es culpa del caché');
    presentador.manda({'t': 'aprobar', 'tipo': 'excusa', 'id': pendiente['id']});
    sala.tick();
    expect((celular.ultimoEstado['excuses']! as List).single, containsPair('text', 'Es culpa del caché'));
    expect(sala.excusasAprobadas(), hasLength(1));
  });

  test('cada persona apoya una pregunta una sola vez', () {
    final autor = entra('cliente-0001')
      ..manda({'t': 'pregunta', 'texto': '¿Flutter sirve para web?'});
    sala.tick();
    final id = ((presentador.ultimoEstado['questions']! as List).single as Map)['id'];
    presentador.manda({'t': 'aprobar', 'tipo': 'pregunta', 'id': id});
    final fan = entra('cliente-0002');
    fan
      ..manda({'t': 'apoyo', 'id': id})
      ..manda({'t': 'apoyo', 'id': id});
    sala.tick();
    final pregunta = (autor.ultimoEstado['questions']! as List).single as Map;
    expect(pregunta['votes'], 1);
  });

  test('los mensajes del público no controlan la charla', () {
    entra('cliente-0001').manda({
      't': 'cue',
      'cue': {'mode': 'rating'},
    });
    expect(sala.modo, 'idle');
  });

  test('las estrellas solo cuentan en la calificación final', () {
    final celular = entra('cliente-0001')..manda({'t': 'estrellas', 'n': 5});
    presentador.manda({
      't': 'cue',
      'cue': {'mode': 'rating'},
    });
    celular
      ..manda({'t': 'estrellas', 'n': 9})
      ..manda({'t': 'estrellas', 'n': 4});
    sala.tick();
    expect(celular.ultimoEstado['rating'], {'average': 4.0, 'total': 1});
  });

  test('el celular del presentador hace de control remoto', () {
    final charla = _Celular(sala, presentador: true);
    presentador.manda({'t': 'nav', 'dir': 'next'});
    expect(charla.recibidos.last, '{"t":"nav","dir":"next"}');
  });

  test('la diapositiva actual llega al guion del presentador', () {
    presentador.manda({
      't': 'diapositiva',
      'id': 'agenda',
      'titulo': 'La agenda',
      'indice': 4,
      'total': 41,
      'paso': 1,
      'pasos': 2,
    });
    sala.tick();
    expect(presentador.ultimoEstado['slide'], containsPair('id', 'agenda'));
  });
}
