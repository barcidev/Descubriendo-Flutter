import 'filtro.dart';
import 'sala.dart' show Reloj;

/// Una pregunta del concurso: el texto, las opciones y cuál es la correcta.
/// Las manda la charla (que es donde viven); el público nunca ve cuál es la
/// correcta antes de que se cierre la pregunta.
class PreguntaConcurso {
  const PreguntaConcurso(this.texto, this.opciones, this.correcta);

  final String texto;
  final List<String> opciones;
  final int correcta;

  static PreguntaConcurso? deJson(Object? json) {
    if (json is! Map) return null;
    final texto = limpio(json['texto'], maximo: 200);
    final opciones = [
      for (final opcion in (json['opciones'] as List?) ?? const [])
        if (limpio(opcion, maximo: 80, minimo: 1) case final texto?) texto,
    ];
    final correcta = json['correcta'];
    if (texto == null || opciones.length < 2 || opciones.length > 4) {
      return null;
    }
    if (correcta is! int || correcta < 0 || correcta >= opciones.length) {
      return null;
    }
    return PreguntaConcurso(texto, opciones, correcta);
  }
}

enum FaseConcurso { intro, pregunta, tabla, podio }

typedef Respuesta = ({int opcion, int ms});

/// El concurso tipo Kahoot del final: preguntas de 30 segundos, puntos por
/// acertar y por responder rápido, y una tabla de posiciones.
///
/// Acertar da de 1000 puntos (al instante) a 500 (en el último segundo);
/// fallar o no responder da 0. Cada persona responde una sola vez.
class Concurso {
  Concurso({Reloj? reloj}) : _reloj = reloj ?? DateTime.now;

  static const duracion = Duration(seconds: 30);

  final Reloj _reloj;
  List<PreguntaConcurso> preguntas = const [];
  FaseConcurso fase = FaseConcurso.intro;
  int indice = -1;
  DateTime? _abierta;

  /// Por pregunta: lo que respondió cada cliente y en cuántos milisegundos.
  final respuestas = <int, Map<String, Respuesta>>{};

  /// El total de cada cliente.
  final puntos = <String, int>{};

  /// Los totales antes de la última pregunta cerrada: de ahí arranca la
  /// animación de la tabla.
  Map<String, int> antes = const {};

  /// Lo que ganó cada cliente en la última pregunta cerrada.
  final ganados = <String, int>{};

  PreguntaConcurso? get actual =>
      indice >= 0 && indice < preguntas.length ? preguntas[indice] : null;

  /// Puntos por acertar en [ms] milisegundos.
  static int puntaje(int ms) {
    final parte = (ms / duracion.inMilliseconds).clamp(0.0, 1.0);
    return (1000 * (1 - parte / 2)).round();
  }

  /// Cuánto le queda a la pregunta abierta.
  Duration get restante {
    final abierta = _abierta;
    if (fase != FaseConcurso.pregunta || abierta == null) return Duration.zero;
    final queda = duracion - _reloj().difference(abierta);
    return queda.isNegative ? Duration.zero : queda;
  }

  bool get vencida => fase == FaseConcurso.pregunta && restante == Duration.zero;

  /// Abre la pregunta [n], si existe y no se ha jugado.
  void abrir(int n) {
    if (n < 0 || n >= preguntas.length || respuestas.containsKey(n)) return;
    indice = n;
    fase = FaseConcurso.pregunta;
    _abierta = _reloj();
    respuestas[n] = {};
  }

  /// La respuesta de [cliente] a la pregunta [n]. Solo cuenta la primera, y
  /// solo mientras la pregunta está abierta.
  bool responder(String cliente, Object? n, Object? opcion) {
    final pregunta = actual;
    if (fase != FaseConcurso.pregunta || n != indice || pregunta == null) {
      return false;
    }
    if (opcion is! int || opcion < 0 || opcion >= pregunta.opciones.length) {
      return false;
    }
    final mapa = respuestas[indice]!;
    if (mapa.containsKey(cliente) || vencida) return false;
    mapa[cliente] = (
      opcion: opcion,
      ms: _reloj().difference(_abierta!).inMilliseconds,
    );
    return true;
  }

  /// Cierra la pregunta abierta y reparte los puntos.
  void cerrar() {
    final pregunta = actual;
    if (fase != FaseConcurso.pregunta || pregunta == null) return;
    antes = Map.of(puntos);
    ganados.clear();
    for (final MapEntry(key: cliente, value: respuesta)
        in respuestas[indice]!.entries) {
      final gano =
          respuesta.opcion == pregunta.correcta ? puntaje(respuesta.ms) : 0;
      ganados[cliente] = gano;
      puntos[cliente] = (puntos[cliente] ?? 0) + gano;
    }
    fase = FaseConcurso.tabla;
  }

  void terminar() {
    cerrar();
    if (indice >= 0) fase = FaseConcurso.podio;
  }

  /// Empieza de nuevo, con las mismas preguntas.
  void reiniciar() {
    fase = FaseConcurso.intro;
    indice = -1;
    _abierta = null;
    respuestas.clear();
    puntos.clear();
    ganados.clear();
    antes = const {};
  }

  /// [jugadores] ordenados: más puntos primero; si empatan, por nombre.
  static List<String> ordenar(
    Map<String, int> totales,
    Map<String, String> jugadores,
  ) =>
      jugadores.keys.toList()
        ..sort((a, b) {
          final porPuntos = (totales[b] ?? 0).compareTo(totales[a] ?? 0);
          return porPuntos != 0
              ? porPuntos
              : jugadores[a]!.compareTo(jugadores[b]!);
        });
}
