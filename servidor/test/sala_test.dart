import 'dart:convert';
import 'dart:math' as math;

import 'package:servidor/jurado.dart';
import 'package:servidor/sala.dart';
import 'package:test/test.dart';

/// Un jurado de mentira: devuelve lo que se le diga y anota lo que recibe.
class _Jurado implements Jurado {
  List<String> respuesta = const [];
  bool falla = false;
  final recibidos = <String>[];

  @override
  Future<List<String>> elegir(Ronda ronda, List<Escrito> escritos) async {
    recibidos.addAll(escritos.map((e) => e.texto));
    if (falla) throw Exception('sin cuota');
    return respuesta;
  }
}

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

  test('el nombre llega a la terminal, con el widget como apodo', () {
    final celular = entra('cliente-0001')
      ..manda({'t': 'nombre', 'nombre': '  Ana   María '});
    sala.tick();
    final yo = celular.recibidos
        .map((m) => jsonDecode(m) as Map<String, Object?>)
        .lastWhere((m) => m['t'] == 'yo');
    expect(yo['nombre'], 'Ana María');
    final llegada = (presentador.ultimoEstado['joins']! as List).single as Map;
    expect(llegada['nombre'], 'Ana María');
    expect(llegada['widget'], yo['widget']);
    expect(presentador.ultimoEstado['people'], 1);
  });

  test('un nombre grosero no entra', () {
    final celular = entra('cliente-0001')
      ..manda({'t': 'nombre', 'nombre': 'H1JUEPUTA'});
    expect(celular.recibidos.last, '{"t":"nombre","ok":false}');
    sala.tick();
    expect(presentador.ultimoEstado['joins'], isEmpty);
  });

  test('los apodos se reparten sin repetir mientras alcancen', () {
    final widgets = <Object?>{};
    for (var i = 0; i < 20; i++) {
      final celular = entra('cliente-${i.toString().padLeft(4, '0')}');
      widgets.add((jsonDecode(celular.recibidos.first) as Map)['widget']);
    }
    expect(widgets, hasLength(20));
  });

  test('la lista de asistentes, para los créditos, va en orden de llegada', () {
    entra('cliente-0001').manda({'t': 'nombre', 'nombre': 'Ana'});
    entra('cliente-0002'); // sin nombre: no sale en los créditos
    entra('cliente-0003').manda({'t': 'nombre', 'nombre': 'Luis'});
    presentador.manda({'t': 'asistentes'});
    final respuesta = jsonDecode(presentador.recibidos.last) as Map;
    expect(respuesta['t'], 'asistentes');
    expect([for (final a in respuesta['lista'] as List) (a as Map)['nombre']],
        ['Ana', 'Luis']);
  });

  group('ronda de excusas', () {
    var ahora = DateTime(2026, 10, 28, 18);
    late _Jurado jurado;

    setUp(() {
      ahora = DateTime(2026, 10, 28, 18);
      jurado = _Jurado();
      sala = Sala(azar: math.Random(1), reloj: () => ahora, jurado: jurado);
      presentador = _Celular(sala, presentador: true);
    });

    void abrir() => presentador.manda({
          't': 'cue',
          'cue': {'mode': 'excuse', 'open': true, 'seconds': 60},
        });

    Map<String, Object?> ronda() =>
        presentador.ultimoEstado['excuseRound']! as Map<String, Object?>;

    test('recibe excusas solo mientras corre el tiempo', () async {
      final celular = entra('cliente-0001')
        ..manda({'t': 'excusa', 'texto': 'Antes de abrir'});
      abrir();
      celular.manda({'t': 'excusa', 'texto': '  Es   culpa del caché  '});
      sala.tick();
      expect(ronda()['phase'], 'abierta');
      expect(ronda()['remaining'], 60);
      expect(ronda()['received'], 1);
      ahora = ahora.add(const Duration(seconds: 61));
      celular.manda({'t': 'excusa', 'texto': 'Ya tarde'});
      sala.tick();
      expect(ronda()['phase'], 'eligiendo');
      await pumpEventQueue();
      sala.tick();
      expect(ronda()['phase'], 'lista');
      expect(jurado.recibidos, [('Es culpa del caché')]);
    });

    test('el jurado escoge y GET /excusas responde lo mismo', () async {
      abrir();
      for (var i = 0; i < 6; i++) {
        entra('cliente-000$i').manda({'t': 'excusa', 'texto': 'Excusa número $i'});
      }
      jurado.respuesta = ['6', '3', '1', '5', '2'];
      // Pasar de paso cierra la ronda antes de tiempo.
      presentador.manda({
        't': 'cue',
        'cue': {'mode': 'excuse', 'open': false},
      });
      await pumpEventQueue();
      sala.tick();
      final elegidas = ronda()['picks']! as List;
      expect([for (final e in elegidas) (e as Map)['id']], [6, 3, 1, 5, 2]);
      expect(elegidas.first, {
        'id': 6,
        'texto': 'Excusa número 5',
        'apodo': isA<String>(),
      });
      expect(sala.excusasElegidas(), elegidas);
      expect(ronda()['byAi'], isTrue);
    });

    test('si el jurado falla, hay plan B, y nunca quedan menos de cuatro',
        () async {
      jurado.falla = true;
      abrir();
      entra('cliente-0001').manda({'t': 'excusa', 'texto': 'Se cayó el wifi'});
      ahora = ahora.add(const Duration(minutes: 2));
      sala.tick();
      await pumpEventQueue();
      final elegidas = sala.excusasElegidas();
      expect(elegidas, hasLength(4));
      expect(elegidas.map((e) => e['texto']), contains('Se cayó el wifi'));
      expect(ronda()['byAi'], isFalse);
    });

    test('si nadie escribe, salen las de respaldo', () async {
      abrir();
      ahora = ahora.add(const Duration(minutes: 2));
      sala.tick();
      await pumpEventQueue();
      expect(sala.excusasElegidas(), hasLength(4));
      expect(jurado.recibidos, isEmpty);
    });

    test('lo grosero ni siquiera le llega al jurado', () async {
      abrir();
      entra('cliente-0001').manda({'t': 'excusa', 'texto': 'Fue culpa de ese malparido'});
      entra('cliente-0002').manda({'t': 'excusa', 'texto': 'Era el DNS'});
      ahora = ahora.add(const Duration(minutes: 2));
      sala.tick();
      await pumpEventQueue();
      expect(jurado.recibidos, ['Era el DNS']);
    });
  });

  test('las preguntas se eligen al llegar a su diapositiva', () async {
    final jurado = _Jurado()..respuesta = ['2'];
    sala = Sala(azar: math.Random(1), jurado: jurado);
    presentador = _Celular(sala, presentador: true);
    entra('cliente-0001')
      ..manda({'t': 'pregunta', 'texto': '¿Flutter sirve para web?'})
      ..manda({'t': 'pregunta', 'texto': '¿Y para escritorio?'});
    presentador.manda({
      't': 'cue',
      'cue': {'mode': 'questions'},
    });
    await pumpEventQueue();
    sala.tick();
    final ronda =
        presentador.ultimoEstado['questionRound']! as Map<String, Object?>;
    expect(ronda['received'], 2);
    expect(ronda['picks'], [
      {'id': 2, 'texto': '¿Y para escritorio?', 'apodo': isA<String>()},
    ]);
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
