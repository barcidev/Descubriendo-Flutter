import 'dart:convert';
import 'dart:math' as math;

import 'package:servidor/concurso.dart';
import 'package:servidor/sala.dart';
import 'package:test/test.dart';

/// Un celular (o la charla) de mentira: guarda lo que el servidor le manda.
class _Celular {
  _Celular(this.sala, {bool presentador = false}) {
    conexion = Conexion(enviar: recibidos.add, presentador: presentador);
    sala.entrar(conexion);
  }

  final Sala sala;
  late final Conexion conexion;
  final recibidos = <String>[];

  void manda(Map<String, Object?> mensaje) =>
      sala.recibir(conexion, jsonEncode(mensaje));

  Map<String, Object?> ultimo(String tipo) => recibidos
      .map((m) => jsonDecode(m) as Map<String, Object?>)
      .lastWhere((m) => m['t'] == tipo);
}

const _preguntas = [
  {'texto': '¿Qué lenguaje usa Flutter?', 'opciones': ['Kotlin', 'Dart', 'Swift'], 'correcta': 1},
  {'texto': '¿UI = f(?)', 'opciones': ['estado', 'café'], 'correcta': 0},
];

void main() {
  var ahora = DateTime(2026, 10, 28, 18, 40);
  late Sala sala;
  late _Celular charla;

  setUp(() {
    ahora = DateTime(2026, 10, 28, 18, 40);
    sala = Sala(azar: math.Random(1), reloj: () => ahora);
    charla = _Celular(sala, presentador: true)
      ..manda({'t': 'concurso', 'preguntas': _preguntas});
  });

  _Celular jugador(String id, String nombre) => _Celular(sala)
    ..manda({'t': 'hola', 'id': id})
    ..manda({'t': 'nombre', 'nombre': nombre});

  void paso(String fase, [int? indice]) => charla.manda({
        't': 'cue',
        'cue': {'mode': 'quiz', 'phase': fase, if (indice != null) 'index': indice},
      });

  test('acertar rápido da más puntos que acertar tarde; fallar da cero', () {
    expect(Concurso.puntaje(0), 1000);
    expect(Concurso.puntaje(15000), 750);
    expect(Concurso.puntaje(30000), 500);
    final ana = jugador('cliente-0001', 'Ana');
    final luis = jugador('cliente-0002', 'Luis');
    final eva = jugador('cliente-0003', 'Eva');
    paso('pregunta', 0);
    ana.manda({'t': 'respuesta', 'index': 0, 'opcion': 1});
    ahora = ahora.add(const Duration(seconds: 15));
    luis.manda({'t': 'respuesta', 'index': 0, 'opcion': 1});
    eva.manda({'t': 'respuesta', 'index': 0, 'opcion': 0});
    // Respondieron todos: se cierra sola, sin esperar los 30 s.
    sala.tick();
    expect(sala.concurso.fase, FaseConcurso.tabla);
    expect(sala.concurso.puntos, {
      'cliente-0001': 1000,
      'cliente-0002': 750,
      'cliente-0003': 0,
    });
    final resultado = eva.ultimo('concurso-mio');
    expect(resultado['gained'], 0);
    expect(resultado['rank'], 3);
  });

  test('a los 30 segundos se cierra aunque falte gente', () {
    final ana = jugador('cliente-0001', 'Ana');
    jugador('cliente-0002', 'Luis');
    paso('pregunta', 0);
    ana.manda({'t': 'respuesta', 'index': 0, 'opcion': 1});
    sala.tick();
    expect(sala.concurso.fase, FaseConcurso.pregunta);
    ahora = ahora.add(const Duration(seconds: 31));
    sala.tick();
    expect(sala.concurso.fase, FaseConcurso.tabla);
  });

  test('el público no ve la respuesta correcta antes de tiempo', () {
    final ana = jugador('cliente-0001', 'Ana');
    jugador('cliente-0002', 'Luis');
    paso('pregunta', 0);
    sala.tick();
    final abierta = ana.ultimo('estado')['quiz']! as Map;
    expect(abierta['question'], '¿Qué lenguaje usa Flutter?');
    expect(abierta.containsKey('correct'), isFalse);
    paso('tabla', 0);
    sala.tick();
    final cerrada = ana.ultimo('estado')['quiz']! as Map;
    expect(cerrada['correct'], 1);
  });

  test('solo cuenta la primera respuesta, y solo de quien dio su nombre', () {
    final ana = jugador('cliente-0001', 'Ana');
    final anonimo = _Celular(sala)..manda({'t': 'hola', 'id': 'cliente-0009'});
    paso('pregunta', 0);
    ana
      ..manda({'t': 'respuesta', 'index': 0, 'opcion': 0})
      ..manda({'t': 'respuesta', 'index': 0, 'opcion': 1});
    anonimo.manda({'t': 'respuesta', 'index': 0, 'opcion': 1});
    expect(sala.concurso.respuestas[0], {'cliente-0001': (opcion: 0, ms: 0)});
  });

  test('volver a la portada empieza un concurso nuevo (por si hubo ensayo)', () {
    final ana = jugador('cliente-0001', 'Ana');
    paso('pregunta', 0);
    ana.manda({'t': 'respuesta', 'index': 0, 'opcion': 1});
    sala.tick();
    expect(sala.concurso.puntos, {'cliente-0001': 1000});
    paso('intro');
    paso('pregunta', 0);
    expect(sala.concurso.fase, FaseConcurso.pregunta);
    expect(sala.concurso.puntos, isEmpty);
  });

  test('la tabla dice el puesto de antes, para animar quién sube', () {
    final ana = jugador('cliente-0001', 'Ana');
    final luis = jugador('cliente-0002', 'Luis');
    paso('pregunta', 0);
    ana.manda({'t': 'respuesta', 'index': 0, 'opcion': 1});
    luis.manda({'t': 'respuesta', 'index': 0, 'opcion': 0});
    sala.tick();
    paso('pregunta', 1);
    luis.manda({'t': 'respuesta', 'index': 1, 'opcion': 0});
    ahora = ahora.add(const Duration(seconds: 20));
    ana.manda({'t': 'respuesta', 'index': 1, 'opcion': 1});
    sala.tick();
    paso('podio');
    sala.tick();
    final quiz = charla.ultimo('estado')['quiz']! as Map;
    expect(quiz['phase'], 'podio');
    final tabla = quiz['board']! as List;
    expect([for (final fila in tabla) (fila as Map)['name']], ['Ana', 'Luis']);
    expect((tabla.last as Map)['rankBefore'], 2);
    expect((tabla.last as Map)['gained'], 1000);
  });
}
