import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../engine/browser.dart';
import 'live_config.dart';
import 'live_models.dart';

/// Cómo está la charla frente al servidor de votaciones.
enum PresenterAccess {
  /// Sin servidor, o el presentador eligió presentar a mano alzada.
  none,

  /// Hay servidor, pero falta escribir el token del presentador.
  login,

  /// Revisando el token o la sesión guardada.
  checking,

  /// Modo presentador: la charla maneja los celulares.
  granted,
}

/// El lado de la charla en la conversación con los celulares.
///
/// Sin servidor (o si se cae a mitad de la charla) nada se bloquea: las
/// votaciones pasan a «mano alzada» y los conteos se suman con el teclado.
/// Para ensayar sin público hay un modo de audiencia simulada.
class LiveController extends ChangeNotifier {
  LiveController({this.config = const LiveConfig(), this.browser});

  final LiveConfig config;

  /// Donde se guarda la sesión del presentador entre recargas.
  final Browser? browser;

  static const _sessionKey = 'charla.sesion';

  /// La dirección que se muestra junto al QR.
  String get joinUrl => config.joinUrl;

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Timer? _reconnect;
  Timer? _heartbeat;
  int _attempts = 0;
  bool _disposed = false;

  bool _socketOpen = false;
  PresenterAccess _access = PresenterAccess.none;
  String? _loginError;
  String? _pendingToken;
  int _connected = 0;
  AudienceCue _cue = const AudienceCue.idle();
  final _serverResults = <String, PollResults>{};
  final _manualResults = <String, PollResults>{};
  int _counter = 0;
  int _manualCounter = 0;
  List<AudienceText> _excuses = const [];
  List<AudienceText> _questions = const [];
  double _rating = 0;
  int _ratings = 0;
  Timer? _simulation;
  final _reactions = StreamController<String>.broadcast();
  final _navigation = StreamController<String>.broadcast();
  Map<String, Object?> _slide = const {};

  /// Conectado y con el modo presentador concedido.
  bool get online => _socketOpen && _access == PresenterAccess.granted;

  PresenterAccess get access => _access;

  /// Por qué no se pudo entrar la última vez.
  String? get loginError => _loginError;

  /// El WebSocket está abierto (el servidor gratis puede tardar en despertar).
  bool get socketOpen => _socketOpen;
  bool get simulating => _simulation != null;
  AudienceCue get cue => _cue;

  /// Personas con la página abierta.
  int get connected => _connected;

  /// Los toques del «contador más grande del mundo».
  int get counter => _counter + _manualCounter;

  /// Excusas aprobadas, la más nueva primero.
  List<AudienceText> get excuses => _excuses;

  /// Preguntas aprobadas, las más apoyadas primero.
  List<AudienceText> get questions => _questions;

  double get rating => _rating;
  int get ratings => _ratings;

  /// Cada reacción que llega del público: `fuego`, `bug` o `aplauso`.
  Stream<String> get reactions => _reactions.stream;

  /// Órdenes del celular del presentador: `next` o `prev`.
  Stream<String> get navigation => _navigation.stream;

  /// Los votos de [pollId]: los del servidor más los de mano alzada.
  PollResults resultsFor(String pollId) =>
      (_serverResults[pollId] ?? PollResults.empty).merge(
        _manualResults[pollId] ?? PollResults.empty,
      );

  String? get _session {
    final stored = browser?.read(_sessionKey);
    return stored == null || stored.isEmpty ? null : stored;
  }

  set _session(String? value) => browser?.write(_sessionKey, value ?? '');

  /// Empieza a hablar con el servidor, si hay uno configurado. Con una
  /// sesión guardada entra sola; si no, la charla pide el token.
  void start() {
    if (!config.enabled) return;
    _access = _session == null ? PresenterAccess.login : PresenterAccess.checking;
    _connect();
  }

  /// El presentador escribió el token. Si el servidor todavía está
  /// despertando, sale apenas se abra la conexión.
  void login(String token) {
    if (token.isEmpty) return;
    _access = PresenterAccess.checking;
    _loginError = null;
    if (_socketOpen) {
      _send({'t': 'login', 'token': token});
    } else {
      _pendingToken = token;
    }
    notifyListeners();
  }

  /// Presentar sin servidor: las votaciones quedan a mano alzada.
  void skipLogin() {
    _access = PresenterAccess.none;
    _pendingToken = null;
    _reconnect?.cancel();
    _heartbeat?.cancel();
    final channel = _channel;
    _channel = null;
    _socketOpen = false;
    unawaited(_subscription?.cancel());
    unawaited(channel?.sink.close());
    notifyListeners();
  }

  /// Cierra la sesión en esta máquina y vuelve a pedir el token.
  void logout() {
    if (!config.enabled) return;
    _session = null;
    _loginError = null;
    if (_access == PresenterAccess.none) {
      _access = PresenterAccess.login;
      _connect();
    } else {
      _access = PresenterAccess.login;
      // Una conexión nueva entra como público, sin el rol anterior.
      unawaited(_channel?.sink.close());
    }
    notifyListeners();
  }

  void _connect() {
    if (_disposed) return;
    final uri = config.socket!;
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _subscription = channel.stream.listen(
      _onMessage,
      onDone: _onClosed,
      onError: (Object _) => _onClosed(),
      cancelOnError: true,
    );
    channel.ready.then((_) {
      if (_channel != channel) return;
      _attempts = 0;
      _socketOpen = true;
      // El token o la sesión van dentro del WebSocket, nunca en la URL.
      if (_pendingToken case final token?) {
        _pendingToken = null;
        _send({'t': 'login', 'token': token});
      } else if (_session case final session?) {
        _send({'t': 'auth', 'sesion': session});
      } else if (_access != PresenterAccess.none) {
        _access = PresenterAccess.login;
      }
      // Un latido cada 20 s: detecta conexiones muertas y mantiene
      // despierto al servidor del plan gratis.
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _send({'t': 'ping'}),
      );
      notifyListeners();
    }, onError: (Object _) => _onClosed());
  }

  void _onClosed() {
    if (_disposed || _access == PresenterAccess.none) return;
    _heartbeat?.cancel();
    unawaited(_subscription?.cancel());
    _channel = null;
    if (_socketOpen) {
      // El modo presentador se conserva: al reconectar, entra con la sesión.
      _socketOpen = false;
      notifyListeners();
    }
    _reconnect?.cancel();
    final wait = Duration(seconds: math.min(1 << _attempts, 8));
    _attempts = math.min(_attempts + 1, 4);
    _reconnect = Timer(wait, _connect);
  }

  void _send(Map<String, Object?> message) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(message));
    } on Object {
      _onClosed();
    }
  }

  void _onMessage(Object? message) {
    if (message is! String) return;
    final json = jsonDecode(message);
    if (json is! Map<String, Object?>) return;
    if (json case {'t': 'nav', 'dir': final String direction}) {
      _navigation.add(direction);
      return;
    }
    if (json['t'] == 'acceso') {
      _onAccess(json);
      return;
    }
    if (json['t'] != 'estado') return;
    _connected = (json['connected'] as num? ?? 0).toInt();
    _counter = (json['counter'] as num? ?? 0).toInt();
    final polls = json['polls'] as Map? ?? const {};
    _serverResults
      ..clear()
      ..addAll({
        for (final MapEntry(:key, :value) in polls.entries)
          key as String: PollResults.fromJson(value as Map<String, Object?>),
      });
    List<AudienceText> visible(Object? list) => [
      for (final item in (list as List? ?? const []))
        if (item case final Map<String, Object?> map
            when map['approved'] == true && map['hidden'] != true)
          AudienceText.fromJson(map),
    ];
    _excuses = visible(json['excuses']).reversed.toList();
    _questions = visible(json['questions'])
      ..sort((a, b) => b.votes.compareTo(a.votes));
    final rating = json['rating'] as Map? ?? const {};
    _rating = (rating['average'] as num? ?? 0).toDouble();
    _ratings = (rating['total'] as num? ?? 0).toInt();
    final reactions = json['reactions'] as Map? ?? const {};
    reactions.forEach((kind, count) {
      for (var i = 0; i < math.min((count as num).toInt(), 12); i++) {
        _reactions.add(kind as String);
      }
    });
    notifyListeners();
  }

  void _onAccess(Map<String, Object?> answer) {
    if (answer['ok'] == true) {
      if (answer['sesion'] case final String session) _session = session;
      _access = PresenterAccess.granted;
      _loginError = null;
      _send({'t': 'cue', 'cue': _cue.toJson()});
      if (_slide.isNotEmpty) _send({'t': 'diapositiva', ..._slide});
    } else {
      _access = PresenterAccess.login;
      _loginError = switch (answer['error']) {
        'clave' => 'Token incorrecto. Te quedan ${answer['restantes']} intentos.',
        'bloqueado' => 'Demasiados intentos. Espera ${answer['espera']} s.',
        'sin-clave' => 'El servidor no tiene token configurado (PRESENTER_TOKEN).',
        'sesion' => 'La sesión venció. Escribe el token otra vez.',
        _ => 'No se pudo entrar.',
      };
      if (answer['error'] == 'sesion') _session = null;
    }
    notifyListeners();
  }

  /// En qué diapositiva vamos, para el guion en el celular del presentador.
  void setSlide({
    required String id,
    required String title,
    required int index,
    required int total,
    required int step,
    required int steps,
  }) {
    _slide = {
      'id': id,
      'titulo': title,
      'indice': index,
      'total': total,
      'paso': step,
      'pasos': steps,
    };
    if (_access == PresenterAccess.granted) _send({'t': 'diapositiva', ..._slide});
  }

  /// Lo que deben mostrar los celulares ahora.
  void setCue(AudienceCue cue) {
    if (cue == _cue) return;
    _cue = cue;
    if (_access == PresenterAccess.granted) _send({'t': 'cue', 'cue': cue.toJson()});
    notifyListeners();
  }

  /// Mano alzada: suma (o resta, con [delta] negativo) votos a una opción.
  void raiseHands(String pollId, String option, int delta) {
    final current = _manualResults[pollId] ?? PollResults.empty;
    final next = current.add(option, delta);
    // Sin servidor no hay votantes contados: se toma la opción más votada
    // como el total de la sala, para que las barras sigan siendo legibles.
    final most = next.counts.values.fold(0, math.max);
    _manualResults[pollId] = PollResults(counts: next.counts, voters: most);
    notifyListeners();
  }

  void tap([int count = 1]) {
    _manualCounter += count;
    notifyListeners();
  }

  /// Público de ensayo: votos, toques y reacciones al azar, como en una
  /// sala real. Solo suma localmente: no toca el servidor.
  void toggleSimulation() {
    if (_simulation != null) {
      _simulation!.cancel();
      _simulation = null;
    } else {
      final random = math.Random(42);
      _simulation = Timer.periodic(
        const Duration(milliseconds: 280),
        (_) => _simulate(random),
      );
    }
    notifyListeners();
  }

  static const _rehearsalExcuses = [
    'En staging no pasaba, lo juro.',
    'El cliente tiene el celular en modo ahorro.',
    'Fue culpa del merge de las 5:59 p. m.',
  ];

  void _simulate(math.Random random) {
    if (!online && _connected < 64) _connected += random.nextInt(4);
    final poll = _cue.poll;
    if (_cue.mode == AudienceMode.poll && poll != null && _cue.open) {
      final current = _manualResults[poll.id] ?? PollResults.empty;
      if (current.voters < 64) {
        var next = current.add('', 0, voters: 1);
        // Las primeras opciones pesan un poco más, como en la vida real.
        for (final (index, option) in poll.options.indexed) {
          final weight = 0.55 - index * 0.05 + (option.correct ? 0.15 : 0);
          final picked = poll.multiple
              ? random.nextDouble() < weight
              : index == _weightedPick(random, poll.options.length);
          if (picked) next = next.add(option.id, 1);
        }
        _manualResults[poll.id] = next;
      }
    } else if (_cue.mode == AudienceMode.counter) {
      _manualCounter += random.nextInt(9);
    } else if (_cue.mode == AudienceMode.excuse &&
        _excuses.length < _rehearsalExcuses.length &&
        random.nextDouble() < 0.08) {
      _excuses = [
        AudienceText(
          id: 'ensayo-${_excuses.length}',
          text: _rehearsalExcuses[_excuses.length],
          author: 'Expanded',
          approved: true,
        ),
        ..._excuses,
      ];
    }
    if (random.nextDouble() < 0.12) {
      _reactions.add(const ['fuego', 'bug', 'aplauso'][random.nextInt(3)]);
    }
    notifyListeners();
  }

  int _weightedPick(math.Random random, int count) {
    final weights = [for (var i = 0; i < count; i++) 1.0 / (i + 1.4)];
    final total = weights.reduce((a, b) => a + b);
    var roll = random.nextDouble() * total;
    for (final (index, weight) in weights.indexed) {
      roll -= weight;
      if (roll <= 0) return index;
    }
    return count - 1;
  }

  @override
  void dispose() {
    _disposed = true;
    _simulation?.cancel();
    _reconnect?.cancel();
    _heartbeat?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_channel?.sink.close());
    unawaited(_reactions.close());
    unawaited(_navigation.close());
    super.dispose();
  }
}
