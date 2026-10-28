import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../engine/browser.dart';
import 'fallbacks.dart';
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
  int _people = 0;
  List<Arrival> _arrivals = const [];
  List<Arrival> _attendees = const [];
  TextRound _excuseRound = TextRound.closed;
  TextRound _questionRound = TextRound.closed;
  List<AudienceText>? _backupPicks;
  Timer? _localRound;
  final _random = math.Random();
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

  /// Personas que ya escribieron su nombre.
  int get people => _people;

  /// Las últimas llegadas, la más nueva al final.
  List<Arrival> get arrivals => _arrivals;

  /// Todos los que dieron su nombre, en orden de llegada: los créditos.
  List<Arrival> get attendees => _attendees;

  /// La ronda de excusas: el servidor la lleva; sin él, la charla.
  TextRound get excuseRound => _excuseRound;

  /// Las preguntas que escogió la IA, cuando llegan a su diapositiva.
  TextRound get questionRound => _questionRound;

  /// Las excusas que salieron en pantalla. Mientras no haya ronda, las de
  /// respaldo: así la demo de la API muestra lo mismo que se vio antes.
  List<AudienceText> get shownExcuses =>
      _excuseRound.phase == RoundPhase.ready && _excuseRound.picks.isNotEmpty
      ? _excuseRound.picks
      : _backupPicks ??= pickBackupExcuses(_random);

  double get rating => _rating;
  int get ratings => _ratings;

  /// Cada reacción que llega del público: `fuego`, `bug` o `aplauso`.
  Stream<String> get reactions => _reactions.stream;

  /// Órdenes del celular del presentador: `next` o `prev`.
  Stream<String> get navigation => _navigation.stream;

  /// Los votos de toda la charla: cada persona cuenta una vez por votación.
  int get totalVotes => {..._serverResults.keys, ..._manualResults.keys}
      .fold(0, (total, id) => total + resultsFor(id).voters);

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
    if (json['t'] == 'asistentes') {
      _attendees = [
        for (final (index, item) in (json['lista'] as List? ?? const []).indexed)
          if (item case final Map<String, Object?> map)
            Arrival.fromJson({...map, 'n': index + 1}),
      ];
      notifyListeners();
      return;
    }
    if (json['t'] != 'estado') return;
    final now = DateTime.now();
    _connected = (json['connected'] as num? ?? 0).toInt();
    _counter = (json['counter'] as num? ?? 0).toInt();
    _people = (json['people'] as num? ?? 0).toInt();
    _arrivals = [
      for (final item in (json['joins'] as List? ?? const []))
        if (item case final Map<String, Object?> map) Arrival.fromJson(map),
    ];
    if (json['excuseRound'] case final Map<String, Object?> round) {
      _excuseRound = TextRound.fromJson(round, now);
    }
    if (json['questionRound'] case final Map<String, Object?> round) {
      _questionRound = TextRound.fromJson(round, now);
    }
    final polls = json['polls'] as Map? ?? const {};
    _serverResults
      ..clear()
      ..addAll({
        for (final MapEntry(:key, :value) in polls.entries)
          key as String: PollResults.fromJson(value as Map<String, Object?>),
      });
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
    if (!online) _localRounds(cue);
    notifyListeners();
  }

  /// Pide la lista de asistentes para los créditos. Sin servidor, los del
  /// ensayo.
  void requestAttendees() {
    if (online) {
      _send({'t': 'asistentes'});
    } else {
      _attendees = _simulatedAttendees;
      notifyListeners();
    }
  }

  /// Sin servidor, las rondas siguen las mismas reglas que en el servidor:
  /// la de excusas se abre con su tiempo y, al cerrar, salen las de
  /// respaldo; las preguntas solo existen en el ensayo.
  void _localRounds(AudienceCue cue) {
    switch (cue.mode) {
      case AudienceMode.excuse when cue.open:
        if (_excuseRound.phase != RoundPhase.closed) return;
        _excuseRound = TextRound(
          phase: RoundPhase.open,
          deadline: DateTime.now().add(Duration(seconds: cue.seconds ?? 60)),
        );
        _localRound?.cancel();
        _localRound = Timer.periodic(const Duration(milliseconds: 400), (_) {
          if (_excuseRound.phase != RoundPhase.open) {
            _localRound?.cancel();
          } else if (_excuseRound.remaining(DateTime.now()) == Duration.zero) {
            _closeLocalExcuses();
          } else if (simulating && _random.nextDouble() < 0.35) {
            _excuseRound = _excuseRound.copyWith(received: _excuseRound.received + 1);
            notifyListeners();
          }
        });
      case AudienceMode.excuse:
        if (_excuseRound.phase == RoundPhase.open) _closeLocalExcuses();
      case AudienceMode.questions:
        if (_questionRound.phase != RoundPhase.closed) return;
        _questionRound = const TextRound(phase: RoundPhase.choosing);
        Timer(const Duration(seconds: 3), () {
          if (_disposed) return;
          _questionRound = TextRound(
            phase: RoundPhase.ready,
            received: simulating ? 14 : 0,
            picks: [
              if (simulating)
                for (final (index, (text, author)) in rehearsalQuestions.indexed)
                  AudienceText(id: 'q$index', text: text, author: author, approved: true),
            ],
          );
          notifyListeners();
        });
      default:
        break;
    }
  }

  void _closeLocalExcuses() {
    _localRound?.cancel();
    _excuseRound = _excuseRound.copyWith(phase: RoundPhase.choosing);
    notifyListeners();
    Timer(const Duration(milliseconds: 2500), () {
      if (_disposed) return;
      _excuseRound = _excuseRound.copyWith(
        phase: RoundPhase.ready,
        picks: _backupPicks ??= pickBackupExcuses(_random),
      );
      notifyListeners();
    });
  }

  /// Vuelve a empezar las rondas locales (para ensayar otra vez).
  void resetRounds() {
    _localRound?.cancel();
    _excuseRound = TextRound.closed;
    _questionRound = TextRound.closed;
    _backupPicks = null;
    if (online) {
      _send({'t': 'reiniciar', 'que': 'excusas'});
      _send({'t': 'reiniciar', 'que': 'preguntas'});
    }
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

  final _simulatedAttendees = <Arrival>[];

  void _simulate(math.Random random) {
    if (!online && _connected < 64) _connected += random.nextInt(4);
    // Llegan personas con nombre y apodo, como en la sala.
    if (!online && _simulatedAttendees.length < 60 && random.nextDouble() < 0.3) {
      final number = _simulatedAttendees.length + 1;
      final arrival = Arrival(
        number: number,
        name: rehearsalNames[random.nextInt(rehearsalNames.length)],
        widget: rehearsalWidgets[random.nextInt(rehearsalWidgets.length)],
      );
      _simulatedAttendees.add(arrival);
      _people = number;
      _arrivals = [..._arrivals.skip(math.max(0, _arrivals.length - 39)), arrival];
    }
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
    _localRound?.cancel();
    _reconnect?.cancel();
    _heartbeat?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_channel?.sink.close());
    unawaited(_reactions.close());
    unawaited(_navigation.close());
    super.dispose();
  }
}
