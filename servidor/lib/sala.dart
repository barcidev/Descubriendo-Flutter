import 'dart:async';
import 'dart:convert';
import 'dart:io' show stdout;
import 'dart:math' as math;

import 'filtro.dart';
import 'jurado.dart';
import 'personas.dart';

typedef Reloj = DateTime Function();

/// Una conexión abierta: un celular del público o el presentador.
class Conexion {
  Conexion({required this.enviar, required this.presentador, Reloj? reloj})
      : _toques = Cubeta(capacidad: 60, porSegundo: 30, reloj: reloj),
        _reacciones = Cubeta(capacidad: 6, porSegundo: 3, reloj: reloj);

  final void Function(String mensaje) enviar;

  /// Toda conexión entra como público; pasa a presentador al escribir la
  /// clave correcta (ver Llave).
  bool presentador;

  /// El id que el celular guarda en su almacenamiento: sobrevive a las
  /// reconexiones, así que nadie vota dos veces recargando la página.
  String? cliente;

  final Cubeta _toques;
  final Cubeta _reacciones;
}

/// Límite de ritmo: se llena con el tiempo y cada acción gasta fichas.
class Cubeta {
  Cubeta({required this.capacidad, required this.porSegundo, Reloj? reloj})
      : _reloj = reloj ?? DateTime.now,
        _fichas = capacidad.toDouble();

  final int capacidad;
  final double porSegundo;
  final Reloj _reloj;
  double _fichas;
  DateTime? _ultima;

  bool tomar([int cantidad = 1]) {
    final ahora = _reloj();
    final antes = _ultima;
    if (antes != null) {
      final segundos = ahora.difference(antes).inMicroseconds / 1e6;
      _fichas = math.min(capacidad.toDouble(), _fichas + segundos * porSegundo);
    }
    _ultima = ahora;
    if (_fichas < cantidad) return false;
    _fichas -= cantidad;
    return true;
  }
}

/// Alguien del público: su nombre (para los créditos del final) y el
/// widget que le tocó, que es su apodo durante la charla.
class Asistente {
  Asistente(this.persona);

  final Persona persona;
  String? nombre;
}

/// Una excusa o una pregunta escrita por el público.
class Texto {
  Texto({
    required this.id,
    required this.texto,
    required this.apodo,
    required this.cliente,
  });

  final int id;
  final String texto;
  final String apodo;
  final String cliente;

  /// El contrato de `GET /excusas`: lo mismo que muestra la charla.
  Map<String, Object?> toJson() => {'id': id, 'texto': texto, 'apodo': apodo};
}

enum Fase { cerrada, abierta, eligiendo, lista }

/// Una ronda de excusas o de preguntas: se reciben textos y, al cerrar, el
/// jurado escoge los que salen en pantalla.
class RondaDeTextos {
  RondaDeTextos(this.ronda);

  final Ronda ronda;
  final textos = <Texto>[];
  Fase fase = Fase.cerrada;
  DateTime? cierre;
  List<Map<String, Object?>> elegidas = const [];

  /// Si la elección la hizo la IA (o el plan B).
  bool porIA = false;

  /// Cambia al reiniciar: una elección vieja que llegue tarde se ignora.
  int generacion = 0;
}

const _modos = {
  'idle',
  'poll',
  'counter',
  'excuse',
  'questions',
  'rating',
  'credits',
  'crash',
};
const _reaccionesValidas = {'fuego', 'bug', 'aplauso'};
final _idValido = RegExp(r'^[A-Za-z0-9_-]{8,64}$');

/// El estado de la charla: quién está conectado, qué se está votando y lo
/// que escribió el público. No sabe nada de HTTP: recibe textos y manda
/// textos, así se puede probar sin red.
class Sala {
  Sala({math.Random? azar, Reloj? reloj, Jurado? jurado})
      : _azar = azar ?? math.Random(),
        _reloj = reloj ?? DateTime.now,
        _jurado = jurado;

  final math.Random _azar;
  final Reloj _reloj;
  final Jurado? _jurado;

  final _audiencia = <Conexion>{};
  final _presentadores = <Conexion>{};
  Map<String, Object?> _cue = const {
    'mode': 'idle',
    'open': false,
    'revealed': false
  };

  /// Por encuesta: lo que marcó cada cliente.
  final _votos = <String, Map<String, List<String>>>{};
  final _opciones = <String, List<String>>{};
  final _multiple = <String, bool>{};
  int _contador = 0;
  final _excusas = RondaDeTextos(Ronda.excusas);
  final _preguntas = RondaDeTextos(Ronda.preguntas);
  final _estrellas = <String, int>{};
  final _reacciones = {for (final r in _reaccionesValidas) r: 0};

  /// Por cliente, en orden de llegada.
  final _asistentes = <String, Asistente>{};

  /// Las últimas personas que dijeron su nombre, para la terminal del
  /// inicio: `{n, nombre, widget}`, con `n` creciente.
  final _llegadas = <Map<String, Object?>>[];
  int _llegada = 0;

  /// En qué diapositiva va la charla, para el guion del presentador.
  Map<String, Object?> _diapositiva = const {};
  int _siguiente = 1;
  bool _cambio = true;

  /// Celulares que ya se presentaron.
  int get conectados => _audiencia.where((c) => c.cliente != null).length;

  int get contador => _contador;

  String get modo => _cue['mode']! as String;

  RondaDeTextos get excusas => _excusas;
  RondaDeTextos get preguntas => _preguntas;

  void entrar(Conexion conexion) {
    (conexion.presentador ? _presentadores : _audiencia).add(conexion);
    if (conexion.presentador) {
      conexion.enviar(jsonEncode(_estadoPresentador(const {})));
    }
    _cambio = true;
  }

  /// La clave fue correcta: la conexión pasa a ser del presentador.
  void promover(Conexion conexion) {
    if (conexion.presentador) return;
    _audiencia.remove(conexion);
    conexion.presentador = true;
    _presentadores.add(conexion);
    conexion.enviar(jsonEncode(_estadoPresentador(const {})));
    _cambio = true;
  }

  void salir(Conexion conexion) {
    _audiencia.remove(conexion);
    _presentadores.remove(conexion);
    _cambio = true;
  }

  void recibir(Conexion conexion, String mensaje) {
    final Object? json;
    try {
      json = jsonDecode(mensaje);
    } on FormatException {
      return;
    }
    if (json is! Map<String, Object?>) return;
    final tipo = json['t'];
    if (tipo == 'ping') {
      conexion.enviar('{"t":"pong"}');
      return;
    }
    if (conexion.presentador) {
      _comando(conexion, json);
    } else {
      _publico(conexion, json);
    }
  }

  /// Cada pocos milisegundos: si algo cambió, todos reciben el estado nuevo.
  /// Se serializa una sola vez por grupo, no una vez por celular.
  void tick() {
    if (_excusas.fase == Fase.abierta &&
        !_reloj().isBefore(_excusas.cierre!)) {
      unawaited(_elegir(_excusas));
    }
    final reacciones = Map.of(_reacciones);
    final hayReacciones = reacciones.values.any((n) => n > 0);
    if (!_cambio && !hayReacciones) return;
    if (_cambio) {
      final publico = jsonEncode(_estadoPublico());
      for (final conexion in _audiencia) {
        if (conexion.cliente != null) conexion.enviar(publico);
      }
    }
    final presentador = jsonEncode(_estadoPresentador(reacciones));
    for (final conexion in _presentadores) {
      conexion.enviar(presentador);
    }
    _reacciones.updateAll((reaccion, _) => 0);
    _cambio = false;
  }

  /// Las excusas que escogió el jurado: lo que responde `GET /excusas`.
  List<Map<String, Object?>> excusasElegidas() =>
      _excusas.fase == Fase.lista ? _excusas.elegidas : const [];

  void _publico(Conexion conexion, Map<String, Object?> json) {
    final tipo = json['t'];
    if (tipo == 'hola') {
      final id = json['id'];
      if (id is! String || !_idValido.hasMatch(id)) return;
      conexion.cliente = id;
      final asistente = _asistentes[id] ??= _nuevoAsistente(json['widget']);
      // Si el servidor se reinició, el celular trae el nombre guardado.
      if (asistente.nombre == null) _bautizar(asistente, json['nombre']);
      _presentarse(conexion, asistente);
      conexion.enviar(jsonEncode(_estadoPublico()));
      _cambio = true;
      return;
    }
    final cliente = conexion.cliente;
    if (cliente == null) return;
    switch (tipo) {
      case 'nombre':
        final asistente = _asistentes[cliente]!;
        if (_bautizar(asistente, json['nombre'])) {
          _presentarse(conexion, asistente);
        } else {
          conexion.enviar('{"t":"nombre","ok":false}');
        }
      case 'voto':
        _votar(cliente, json);
      case 'toque':
        final cantidad = json['n'];
        if (modo == 'counter' &&
            cantidad is int &&
            cantidad > 0 &&
            cantidad <= 25 &&
            conexion._toques.tomar(cantidad)) {
          _contador += cantidad;
          _cambio = true;
        }
      case 'excusa':
        final abierta = _excusas.fase == Fase.abierta &&
            _reloj().isBefore(_excusas.cierre!);
        if (!abierta) return;
        _escribir(_excusas, cliente, json['texto'], maximo: 140, porPersona: 3);
        conexion.enviar(jsonEncode({'t': 'mios', ..._historial(cliente)}));
      case 'pregunta':
        _escribir(_preguntas, cliente, json['texto'],
            maximo: 200, porPersona: 5);
        conexion.enviar(jsonEncode({'t': 'mios', ..._historial(cliente)}));
      case 'reaccion':
        final reaccion = json['r'];
        if (reaccion is String &&
            _reaccionesValidas.contains(reaccion) &&
            conexion._reacciones.tomar()) {
          _reacciones[reaccion] = _reacciones[reaccion]! + 1;
        }
      case 'estrellas':
        final estrellas = json['n'];
        if (modo == 'rating' &&
            estrellas is int &&
            estrellas >= 1 &&
            estrellas <= 5) {
          _estrellas[cliente] = estrellas;
          _cambio = true;
        }
    }
  }

  /// Un apodo que nadie más tenga: primero los widgets de la lista, después
  /// las variantes y, si todo se acabó, un SizedBox con su propia altura. Si
  /// el celular ya traía uno (porque el servidor se reinició) y sigue libre,
  /// se lo devuelve.
  Asistente _nuevoAsistente([Object? anterior]) {
    final usados = {
      for (final asistente in _asistentes.values) asistente.persona.widget,
    };
    final suyo = personaDe(anterior);
    if (suyo != null && !usados.contains(suyo.widget)) return Asistente(suyo);
    for (final grupo in const [personas, variantes]) {
      final libres = [
        for (final persona in grupo)
          if (!usados.contains(persona.widget)) persona,
      ];
      if (libres.isNotEmpty) {
        return Asistente(libres[_azar.nextInt(libres.length)]);
      }
    }
    var altura = _asistentes.length + 1;
    while (usados.contains(sizedBoxDe(altura).widget)) {
      altura++;
    }
    return Asistente(sizedBoxDe(altura));
  }

  /// Guarda el nombre si sirve. La primera vez, avisa en la terminal.
  bool _bautizar(Asistente asistente, Object? valor) {
    final nombre = nombreValido(valor);
    if (nombre == null) return false;
    final primeraVez = asistente.nombre == null;
    asistente.nombre = nombre;
    if (primeraVez) {
      _llegadas.add({
        'n': ++_llegada,
        'nombre': nombre,
        'widget': asistente.persona.widget,
      });
      if (_llegadas.length > 40) _llegadas.removeAt(0);
    }
    _cambio = true;
    return true;
  }

  void _presentarse(Conexion conexion, Asistente asistente) {
    final id = conexion.cliente!;
    conexion.enviar(
      jsonEncode({
        't': 'yo',
        ...asistente.persona.toJson(),
        'nombre': asistente.nombre,
        'votos': {
          for (final MapEntry(:key, :value) in _votos.entries)
            if (value[id] case final elegidas?) key: elegidas,
        },
        ..._historial(id),
      }),
    );
  }

  /// Lo que esta persona ya mandó: así, al recargar la página, lo ve igual.
  Map<String, Object?> _historial(String cliente) => {
        'excusas': [
          for (final texto in _excusas.textos)
            if (texto.cliente == cliente) texto.texto,
        ],
        'preguntas': [
          for (final texto in _preguntas.textos)
            if (texto.cliente == cliente) texto.texto,
        ],
        if (_estrellas[cliente] case final estrellas?) 'estrellas': estrellas,
      };

  void _votar(String cliente, Map<String, Object?> json) {
    final poll = _cue['poll'];
    if (modo != 'poll' || _cue['open'] != true || poll is! Map) return;
    final id = poll['id'];
    if (json['poll'] != id || id is! String) return;
    final validas = _opciones[id] ?? const [];
    final elegidas = [
      for (final opcion in (json['opciones'] as List?) ?? const [])
        if (opcion is String && validas.contains(opcion)) opcion,
    ].toSet().toList();
    final votos = _votos.putIfAbsent(id, () => {});
    if (elegidas.isEmpty) {
      votos.remove(cliente);
    } else {
      votos[cliente] = _multiple[id] == true ? elegidas : [elegidas.first];
    }
    _cambio = true;
  }

  void _escribir(
    RondaDeTextos ronda,
    String cliente,
    Object? valor, {
    required int maximo,
    required int porPersona,
  }) {
    final texto = limpio(valor, maximo: maximo);
    if (texto == null) return;
    final lista = ronda.textos;
    if (lista.where((t) => t.cliente == cliente).length >= porPersona) return;
    lista.add(
      Texto(
        id: _siguiente++,
        texto: texto,
        apodo: _asistentes[cliente]?.persona.widget ?? 'Widget',
        cliente: cliente,
      ),
    );
    _cambio = true;
  }

  /// Cierra la ronda y le pide al jurado los textos para la pantalla. Si
  /// no hay jurado o falla, escoge el plan B. Las excusas nunca quedan en
  /// menos de cuatro: se completan con las de respaldo.
  Future<void> _elegir(RondaDeTextos ronda) async {
    if (ronda.fase == Fase.eligiendo) return;
    final generacion = ++ronda.generacion;
    ronda
      ..fase = Fase.eligiendo
      ..cierre = null;
    _cambio = true;
    final textos = [
      for (final texto in ronda.textos)
        if (!esGrosero(texto.texto)) texto,
    ];
    final escritos = [
      for (final texto in textos.take(300))
        (id: '${texto.id}', texto: texto.texto),
    ];
    var ids = <String>[];
    var porIA = false;
    if (escritos.isNotEmpty) {
      final jurado = _jurado;
      if (jurado != null) {
        try {
          ids = await jurado.elegir(ronda.ronda, escritos);
          porIA = true;
        } on Object catch (error) {
          stdout.writeln('El jurado falló (${ronda.ronda.name}): $error');
        }
      }
      if (!porIA) ids = elegirSinIA(ronda.ronda, escritos, _azar);
    }
    if (generacion != ronda.generacion) return;
    final porId = {for (final texto in textos) '${texto.id}': texto};
    final elegidas = <Map<String, Object?>>[
      for (final id in ids.toSet())
        if (porId[id] case final texto?) texto.toJson(),
    ].take(5).toList();
    if (ronda.ronda == Ronda.excusas && elegidas.length < 4) {
      elegidas
        ..addAll(respaldo(4 - elegidas.length, _azar))
        ..shuffle(_azar);
    }
    ronda
      ..elegidas = elegidas
      ..porIA = porIA
      ..fase = Fase.lista;
    _cambio = true;
  }

  void _comando(Conexion conexion, Map<String, Object?> json) {
    switch (json['t']) {
      case 'cue':
        final cue = json['cue'];
        if (cue is! Map<String, Object?> || !_modos.contains(cue['mode'])) {
          return;
        }
        final poll = cue['poll'];
        if (poll is Map<String, Object?> && poll['id'] is String) {
          final id = poll['id']! as String;
          _opciones[id] = [
            for (final opcion in (poll['options'] as List?) ?? const [])
              if (opcion is Map && opcion['id'] is String)
                opcion['id'] as String,
          ];
          _multiple[id] = poll['multiple'] == true;
        }
        _cue = cue;
        _rondas(cue);
        _cambio = true;
      case 'quitar':
        // Por si el jurado deja pasar algo que no debe salir en pantalla.
        final ronda = json['tipo'] == 'pregunta' ? _preguntas : _excusas;
        ronda.elegidas = [
          for (final elegida in ronda.elegidas)
            if (elegida['id'] != json['id']) elegida,
        ];
        _cambio = true;
      case 'asistentes':
        conexion.enviar(jsonEncode({
          't': 'asistentes',
          'lista': [
            for (final asistente in _asistentes.values)
              if (asistente.nombre case final nombre?)
                {'nombre': nombre, 'widget': asistente.persona.widget},
          ],
        }));
      case 'diapositiva':
        _diapositiva = {
          for (final clave in const [
            'id',
            'titulo',
            'indice',
            'total',
            'paso',
            'pasos'
          ])
            if (json[clave] case final valor?
                when valor is String || valor is int)
              clave: valor,
        };
        _cambio = true;
      case 'nav':
        // El celular del presentador hace de control remoto: la orden le
        // llega a la charla, que es otra conexión de presentador.
        final direccion = json['dir'];
        if (direccion == 'next' || direccion == 'prev') {
          final orden = jsonEncode({'t': 'nav', 'dir': direccion});
          for (final conexion in _presentadores) {
            conexion.enviar(orden);
          }
        }
      case 'reiniciar':
        switch (json['que']) {
          case 'contador':
            _contador = 0;
          case 'votos' when json['poll'] is String:
            _votos.remove(json['poll']);
          case 'excusas':
            _reiniciar(_excusas);
          case 'preguntas':
            _reiniciar(_preguntas);
        }
        _cambio = true;
    }
  }

  /// Lo que cada pantalla le pide a las rondas: las excusas se abren con
  /// un tiempo y se cierran al pasar de paso; las preguntas se eligen al
  /// llegar a su diapositiva.
  void _rondas(Map<String, Object?> cue) {
    switch (cue['mode']) {
      case 'excuse' when cue['open'] == true:
        if (_excusas.fase == Fase.cerrada) {
          final segundos = cue['seconds'];
          _excusas
            ..fase = Fase.abierta
            ..cierre = _reloj().add(
              Duration(seconds: segundos is int ? segundos.clamp(5, 300) : 60),
            );
        }
      case 'excuse':
        if (_excusas.fase == Fase.abierta) unawaited(_elegir(_excusas));
      case 'questions':
        if (_preguntas.fase == Fase.cerrada) unawaited(_elegir(_preguntas));
    }
  }

  void _reiniciar(RondaDeTextos ronda) {
    ronda
      ..generacion += 1
      ..fase = Fase.cerrada
      ..cierre = null
      ..elegidas = const [];
  }

  Map<String, Object?> _resultados(String poll) {
    final votos = _votos[poll] ?? const {};
    final conteo = <String, int>{};
    for (final elegidas in votos.values) {
      for (final opcion in elegidas) {
        conteo[opcion] = (conteo[opcion] ?? 0) + 1;
      }
    }
    return {'counts': conteo, 'voters': votos.length};
  }

  Map<String, Object?> _estrellasResumen({bool distribucion = false}) {
    final total = _estrellas.length;
    final suma = _estrellas.values.fold(0, (a, b) => a + b);
    return {
      'average': total == 0 ? 0 : suma / total,
      'total': total,
      if (distribucion)
        'distribution': [
          for (var n = 1; n <= 5; n++)
            _estrellas.values.where((e) => e == n).length,
        ],
    };
  }

  /// Cuánto le queda a la ronda abierta, en segundos.
  double _restante(RondaDeTextos ronda) {
    final cierre = ronda.cierre;
    if (ronda.fase != Fase.abierta || cierre == null) return 0;
    final ms = cierre.difference(_reloj()).inMilliseconds;
    return math.max(0, ms / 1000);
  }

  Map<String, Object?> _ronda(RondaDeTextos ronda, {bool completa = false}) => {
        'phase': ronda.fase.name,
        'remaining': _restante(ronda),
        if (completa) ...{
          'received': ronda.textos.length,
          'byAi': ronda.porIA,
          'picks': ronda.fase == Fase.lista ? ronda.elegidas : const [],
        },
      };

  int get _conNombre =>
      _asistentes.values.where((asistente) => asistente.nombre != null).length;

  Map<String, Object?> _estadoPublico() {
    final poll = _cue['poll'];
    final id = poll is Map ? poll['id'] : null;
    return {
      't': 'estado',
      'cue': _cue,
      'connected': conectados,
      'counter': _contador,
      if (id is String) 'results': _resultados(id),
      'excuseRound': _ronda(_excusas),
      'rating': _estrellasResumen(),
    };
  }

  Map<String, Object?> _estadoPresentador(Map<String, int> reacciones) => {
        't': 'estado',
        'cue': _cue,
        'connected': conectados,
        'people': _conNombre,
        'joins': _llegadas,
        'counter': _contador,
        'polls': {for (final id in _votos.keys) id: _resultados(id)},
        'excuseRound': _ronda(_excusas, completa: true),
        'questionRound': _ronda(_preguntas, completa: true),
        'rating': _estrellasResumen(distribucion: true),
        'reactions': reacciones,
        'slide': _diapositiva,
      };
}
