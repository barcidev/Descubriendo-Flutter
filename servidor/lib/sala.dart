import 'dart:convert';
import 'dart:math' as math;

import 'personas.dart';

typedef Reloj = DateTime Function();

/// Una conexión abierta: un celular del público o el presentador.
class Conexion {
  Conexion({required this.enviar, required this.presentador, Reloj? reloj})
    : _toques = Cubeta(capacidad: 60, porSegundo: 30, reloj: reloj),
      _reacciones = Cubeta(capacidad: 6, porSegundo: 3, reloj: reloj);

  final void Function(String mensaje) enviar;
  final bool presentador;

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

/// Una excusa o una pregunta escrita por el público.
class Texto {
  Texto({
    required this.id,
    required this.texto,
    required this.autor,
    required this.cliente,
  });

  final String id;
  final String texto;
  final String autor;
  final String cliente;
  bool aprobada = false;
  bool oculta = false;
  bool respondida = false;
  final apoyos = <String>{};

  Map<String, Object?> publica() => {
    'id': id,
    'text': texto,
    'author': autor,
    'votes': apoyos.length,
    'done': respondida,
  };

  Map<String, Object?> completa() => {
    ...publica(),
    'approved': aprobada,
    'hidden': oculta,
  };
}

const _modos = {'idle', 'poll', 'counter', 'excuse', 'questions', 'rating'};
const _reaccionesValidas = {'fuego', 'bug', 'aplauso'};
final _idValido = RegExp(r'^[A-Za-z0-9_-]{8,64}$');

/// El estado de la charla: quién está conectado, qué se está votando y lo
/// que escribió el público. No sabe nada de HTTP: recibe textos y manda
/// textos, así se puede probar sin red.
class Sala {
  Sala({math.Random? azar}) : _azar = azar ?? math.Random();

  final math.Random _azar;

  final _audiencia = <Conexion>{};
  final _presentadores = <Conexion>{};
  Map<String, Object?> _cue = const {'mode': 'idle', 'open': false, 'revealed': false};

  /// Por encuesta: lo que marcó cada cliente.
  final _votos = <String, Map<String, List<String>>>{};
  final _opciones = <String, List<String>>{};
  final _multiple = <String, bool>{};
  int _contador = 0;
  final _excusas = <Texto>[];
  final _preguntas = <Texto>[];
  final _estrellas = <String, int>{};
  final _reacciones = {for (final r in _reaccionesValidas) r: 0};
  final _personas = <String, Persona>{};

  /// En qué diapositiva va la charla, para el guion del presentador.
  Map<String, Object?> _diapositiva = const {};
  int _siguiente = 1;
  bool _cambio = true;

  /// Celulares que ya se presentaron.
  int get conectados => _audiencia.where((c) => c.cliente != null).length;

  int get contador => _contador;

  String get modo => _cue['mode']! as String;

  void entrar(Conexion conexion) {
    (conexion.presentador ? _presentadores : _audiencia).add(conexion);
    if (conexion.presentador) {
      conexion.enviar(jsonEncode(_estadoPresentador(const {})));
    }
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
      _comando(json);
    } else {
      _publico(conexion, json);
    }
  }

  /// Cada pocos milisegundos: si algo cambió, todos reciben el estado nuevo.
  /// Se serializa una sola vez por grupo, no una vez por celular.
  void tick() {
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

  /// Las excusas que ya pasaron la moderación, para la demo de FutureBuilder.
  List<Map<String, Object?>> excusasAprobadas() => [
    for (final excusa in _excusas.reversed)
      if (excusa.aprobada && !excusa.oculta) excusa.publica(),
  ];

  void _publico(Conexion conexion, Map<String, Object?> json) {
    final tipo = json['t'];
    if (tipo == 'hola') {
      final id = json['id'];
      if (id is! String || !_idValido.hasMatch(id)) return;
      conexion.cliente = id;
      final persona = _personas.putIfAbsent(
        id,
        () => personas[_azar.nextInt(personas.length)],
      );
      conexion.enviar(
        jsonEncode({
          't': 'yo',
          ...persona.toJson(),
          'votos': {
            for (final MapEntry(:key, :value) in _votos.entries)
              if (value[id] case final elegidas?) key: elegidas,
          },
        }),
      );
      conexion.enviar(jsonEncode(_estadoPublico()));
      _cambio = true;
      return;
    }
    final cliente = conexion.cliente;
    if (cliente == null) return;
    switch (tipo) {
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
        if (modo != 'excuse') return;
        _escribir(_excusas, cliente, json['texto'], maximo: 140, porPersona: 3);
      case 'pregunta':
        _escribir(_preguntas, cliente, json['texto'], maximo: 200, porPersona: 5);
      case 'apoyo':
        final pregunta = _buscar(_preguntas, json['id']);
        if (pregunta != null && pregunta.aprobada && !pregunta.oculta) {
          _cambio = pregunta.apoyos.add(cliente) || _cambio;
        }
      case 'reaccion':
        final reaccion = json['r'];
        if (reaccion is String &&
            _reaccionesValidas.contains(reaccion) &&
            conexion._reacciones.tomar()) {
          _reacciones[reaccion] = _reacciones[reaccion]! + 1;
        }
      case 'estrellas':
        final estrellas = json['n'];
        if (modo == 'rating' && estrellas is int && estrellas >= 1 && estrellas <= 5) {
          _estrellas[cliente] = estrellas;
          _cambio = true;
        }
    }
  }

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
    List<Texto> lista,
    String cliente,
    Object? valor, {
    required int maximo,
    required int porPersona,
  }) {
    final texto = _limpio(valor, maximo: maximo);
    if (texto == null) return;
    if (lista.where((t) => t.cliente == cliente).length >= porPersona) return;
    lista.add(
      Texto(
        id: '${_siguiente++}',
        texto: texto,
        autor: _personas[cliente]?.widget ?? 'Widget',
        cliente: cliente,
      ),
    );
    _cambio = true;
  }

  void _comando(Map<String, Object?> json) {
    switch (json['t']) {
      case 'cue':
        final cue = json['cue'];
        if (cue is! Map<String, Object?> || !_modos.contains(cue['mode'])) return;
        final poll = cue['poll'];
        if (poll is Map<String, Object?> && poll['id'] is String) {
          final id = poll['id']! as String;
          _opciones[id] = [
            for (final opcion in (poll['options'] as List?) ?? const [])
              if (opcion is Map && opcion['id'] is String) opcion['id'] as String,
          ];
          _multiple[id] = poll['multiple'] == true;
        }
        _cue = cue;
        _cambio = true;
      case 'aprobar' || 'ocultar':
        final lista = json['tipo'] == 'pregunta' ? _preguntas : _excusas;
        final texto = _buscar(lista, json['id']);
        if (texto == null) return;
        final aprobar = json['t'] == 'aprobar';
        texto
          ..aprobada = aprobar
          ..oculta = !aprobar;
        _cambio = true;
      case 'respondida':
        final pregunta = _buscar(_preguntas, json['id']);
        if (pregunta == null) return;
        pregunta.respondida = !pregunta.respondida;
        _cambio = true;
      case 'diapositiva':
        _diapositiva = {
          for (final clave in const ['id', 'titulo', 'indice', 'total', 'paso', 'pasos'])
            if (json[clave] case final valor? when valor is String || valor is int)
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
        if (json['que'] == 'contador') _contador = 0;
        if (json['que'] == 'votos' && json['poll'] is String) {
          _votos.remove(json['poll']);
        }
        _cambio = true;
    }
  }

  Texto? _buscar(List<Texto> lista, Object? id) {
    for (final texto in lista) {
      if (texto.id == id) return texto;
    }
    return null;
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
          for (var n = 1; n <= 5; n++) _estrellas.values.where((e) => e == n).length,
        ],
    };
  }

  List<Map<String, Object?>> _preguntasVisibles() {
    final visibles = _preguntas.where((p) => p.aprobada && !p.oculta).toList()
      ..sort((a, b) => b.apoyos.length.compareTo(a.apoyos.length));
    return [for (final pregunta in visibles.take(30)) pregunta.publica()];
  }

  Map<String, Object?> _estadoPublico() {
    final poll = _cue['poll'];
    final id = poll is Map ? poll['id'] : null;
    return {
      't': 'estado',
      'cue': _cue,
      'connected': conectados,
      'counter': _contador,
      if (id is String) 'results': _resultados(id),
      'excuses': excusasAprobadas().take(12).toList(),
      'questions': _preguntasVisibles(),
      'rating': _estrellasResumen(),
    };
  }

  Map<String, Object?> _estadoPresentador(Map<String, int> reacciones) => {
    't': 'estado',
    'cue': _cue,
    'connected': conectados,
    'counter': _contador,
    'polls': {for (final id in _votos.keys) id: _resultados(id)},
    'excuses': [for (final excusa in _excusas) excusa.completa()],
    'questions': [for (final pregunta in _preguntas) pregunta.completa()],
    'rating': _estrellasResumen(distribucion: true),
    'reactions': reacciones,
    'slide': _diapositiva,
  };
}

/// Una línea sin caracteres de control ni espacios de más, recortada.
String? _limpio(Object? valor, {required int maximo}) {
  if (valor is! String) return null;
  final texto = valor
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (texto.length < 3) return null;
  return texto.length > maximo ? texto.substring(0, maximo) : texto;
}
