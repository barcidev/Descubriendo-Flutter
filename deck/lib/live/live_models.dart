import 'package:flutter/foundation.dart';

/// Lo que ve el celular del público en cada momento.
enum AudienceMode { idle, poll, counter, excuse, questions, rating, credits, crash, quiz }

@immutable
class PollOption {
  const PollOption(this.id, this.label, {this.detail, this.correct = false, this.icon});

  final String id;
  final String label;

  /// El ícono de la app que muestra el celular junto a la opción.
  final String? icon;

  /// Una línea de contexto que la diapositiva muestra al revelar.
  final String? detail;
  final bool correct;

  Map<String, Object?> toJson() => {'id': id, 'label': label, 'icon': ?icon};
}

@immutable
class PollSpec {
  const PollSpec({
    required this.id,
    required this.question,
    required this.options,
    this.multiple = false,
  });

  final String id;
  final String question;
  final List<PollOption> options;

  /// Selección múltiple: cada persona puede marcar varias opciones.
  final bool multiple;

  Map<String, Object?> toJson() => {
    'id': id,
    'question': question,
    'multiple': multiple,
    'options': [for (final option in options) option.toJson()],
  };
}

/// Lo que una diapositiva le pide a los celulares mientras está en pantalla.
@immutable
class AudienceCue {
  const AudienceCue.idle() : this._(AudienceMode.idle);

  const AudienceCue.poll(PollSpec poll, {bool open = true, bool revealed = false})
    : this._(AudienceMode.poll, poll: poll, open: open, revealed: revealed);

  const AudienceCue.counter() : this._(AudienceMode.counter);

  /// La ronda de excusas: abierta durante [seconds] segundos. Cerrada,
  /// el jurado escoge las que salen en pantalla.
  const AudienceCue.excuse({bool open = true, int seconds = 60})
    : this._(AudienceMode.excuse, open: open, seconds: seconds);

  const AudienceCue.questions() : this._(AudienceMode.questions);

  const AudienceCue.rating() : this._(AudienceMode.rating);

  const AudienceCue.credits() : this._(AudienceMode.credits);

  /// La pantalla roja también en los celulares; [fixed], ya arreglada.
  const AudienceCue.crash({bool fixed = false})
    : this._(AudienceMode.crash, revealed: fixed);

  /// El concurso del final: [phase] es `intro`, `pregunta`, `tabla` o
  /// `podio`, y [index] la pregunta.
  const AudienceCue.quiz(String phase, {int? index})
    : this._(AudienceMode.quiz, quizPhase: phase, quizIndex: index);

  const AudienceCue._(
    this.mode, {
    this.poll,
    this.open = false,
    this.revealed = false,
    this.seconds,
    this.quizPhase,
    this.quizIndex,
  });

  final AudienceMode mode;
  final PollSpec? poll;

  /// La votación recibe votos.
  final bool open;

  /// Ya se mostró la respuesta: los celulares también la ven.
  final bool revealed;

  /// Cuánto dura la ronda de excusas.
  final int? seconds;

  final String? quizPhase;
  final int? quizIndex;

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    if (poll != null) 'poll': poll!.toJson(),
    'open': open,
    'revealed': revealed,
    if (seconds != null) 'seconds': seconds,
    'phase': ?quizPhase,
    'index': ?quizIndex,
    if (revealed && poll != null)
      'correct': [
        for (final option in poll!.options)
          if (option.correct) option.id,
      ],
  };

  @override
  bool operator ==(Object other) =>
      other is AudienceCue &&
      other.mode == mode &&
      other.poll?.id == poll?.id &&
      other.open == open &&
      other.revealed == revealed &&
      other.quizPhase == quizPhase &&
      other.quizIndex == quizIndex;

  @override
  int get hashCode => Object.hash(mode, poll?.id, open, revealed, quizPhase, quizIndex);
}

/// Los votos de una encuesta: cuántas personas votaron y cuántas marcaron
/// cada opción.
@immutable
class PollResults {
  const PollResults({required this.counts, required this.voters});

  static const empty = PollResults(counts: {}, voters: 0);

  final Map<String, int> counts;
  final int voters;

  int countOf(String option) => counts[option] ?? 0;

  /// La fracción de votantes que marcó [option], de 0 a 1.
  double shareOf(String option) =>
      voters == 0 ? 0 : (countOf(option) / voters).clamp(0, 1);

  PollResults add(String option, int delta, {int voters = 0}) {
    final next = Map.of(counts);
    next[option] = (countOf(option) + delta).clamp(0, 1 << 30);
    return PollResults(
      counts: next,
      voters: (this.voters + voters).clamp(0, 1 << 30),
    );
  }

  PollResults merge(PollResults other) {
    final next = Map.of(counts);
    other.counts.forEach((key, value) => next[key] = (next[key] ?? 0) + value);
    return PollResults(counts: next, voters: voters + other.voters);
  }

  static PollResults fromJson(Map<String, Object?> json) => PollResults(
    counts: {
      for (final MapEntry(:key, :value)
          in (json['counts'] as Map? ?? const {}).entries)
        key as String: (value as num).toInt(),
    },
    voters: (json['voters'] as num? ?? 0).toInt(),
  );
}

/// El apodo escrito como llamada: `Expanded()`. Los que ya traen paréntesis,
/// como `SizedBox(height: 182)`, quedan igual.
String asCall(String widget) => widget.endsWith(')') ? widget : '$widget()';

/// Una pregunta del concurso: viven en la charla y se le mandan al servidor,
/// que es quien lleva los puntos.
@immutable
class QuizQuestion {
  const QuizQuestion(this.text, this.options, this.correct);

  final String text;
  final List<String> options;
  final int correct;

  Map<String, Object?> toJson() => {'texto': text, 'opciones': options, 'correcta': correct};
}

enum QuizPhase { intro, question, board, podium }

/// Una fila de la tabla de posiciones, con el puesto y los puntos de antes
/// de la última pregunta: así se anima quién sube.
@immutable
class QuizRow {
  const QuizRow({
    required this.name,
    required this.widget,
    required this.points,
    required this.before,
    required this.gained,
    required this.rank,
    required this.rankBefore,
  });

  final String name;
  final String widget;
  final int points;
  final int before;
  final int gained;
  final int rank;
  final int rankBefore;

  static QuizRow fromJson(Map<String, Object?> json) => QuizRow(
    name: json['name'] as String? ?? '',
    widget: json['widget'] as String? ?? 'Widget',
    points: (json['points'] as num? ?? 0).toInt(),
    before: (json['before'] as num? ?? 0).toInt(),
    gained: (json['gained'] as num? ?? 0).toInt(),
    rank: (json['rank'] as num? ?? 0).toInt(),
    rankBefore: (json['rankBefore'] as num? ?? 0).toInt(),
  );
}

/// Cómo va el concurso según el servidor (o el ensayo sin servidor).
@immutable
class QuizState {
  const QuizState({
    this.phase = QuizPhase.intro,
    this.index = -1,
    this.deadline,
    this.answered = 0,
    this.players = 0,
    this.distribution = const [],
    this.board = const [],
  });

  static const initial = QuizState();

  final QuizPhase phase;
  final int index;

  /// Cuándo se cierra la pregunta abierta, en la hora de esta máquina.
  final DateTime? deadline;
  final int answered;
  final int players;

  /// Cuántos escogieron cada opción, cuando la pregunta ya se cerró.
  final List<int> distribution;
  final List<QuizRow> board;

  Duration remaining(DateTime now) {
    final end = deadline;
    if (phase != QuizPhase.question || end == null || !end.isAfter(now)) return Duration.zero;
    return end.difference(now);
  }

  static QuizState fromJson(Map<String, Object?> json, DateTime now) {
    final remaining = (json['remaining'] as num? ?? 0).toDouble();
    return QuizState(
      phase: switch (json['phase']) {
        'pregunta' => QuizPhase.question,
        'tabla' => QuizPhase.board,
        'podio' => QuizPhase.podium,
        _ => QuizPhase.intro,
      },
      index: (json['index'] as num? ?? -1).toInt(),
      deadline: now.add(Duration(milliseconds: (remaining * 1000).round())),
      answered: (json['answered'] as num? ?? 0).toInt(),
      players: (json['players'] as num? ?? 0).toInt(),
      distribution: [
        for (final count in (json['distribution'] as List? ?? const [])) (count as num).toInt(),
      ],
      board: [
        for (final row in (json['board'] as List? ?? const []))
          if (row case final Map<String, Object?> map) QuizRow.fromJson(map),
      ],
    );
  }
}

/// Alguien que acaba de escribir su nombre en el celular.
@immutable
class Arrival {
  const Arrival({required this.number, required this.name, required this.widget});

  /// Orden de llegada: crece con cada persona.
  final int number;
  final String name;

  /// El widget que le tocó: su apodo durante la charla.
  final String widget;

  static Arrival fromJson(Map<String, Object?> json) => Arrival(
    number: (json['n'] as num? ?? 0).toInt(),
    name: json['nombre'] as String? ?? '',
    widget: json['widget'] as String? ?? 'Widget',
  );
}

enum RoundPhase { closed, open, choosing, ready }

/// Una ronda de excusas o de preguntas: abierta, eligiendo (la IA está
/// escogiendo) o lista, con lo que sale en pantalla.
@immutable
class TextRound {
  const TextRound({
    this.phase = RoundPhase.closed,
    this.received = 0,
    this.picks = const [],
    this.deadline,
    this.byAi = false,
  });

  static const closed = TextRound();

  final RoundPhase phase;
  final int received;
  final List<AudienceText> picks;

  /// Cuándo se cierra, en la hora de esta máquina.
  final DateTime? deadline;
  final bool byAi;

  Duration remaining(DateTime now) {
    final end = deadline;
    if (phase != RoundPhase.open || end == null || !end.isAfter(now)) {
      return Duration.zero;
    }
    return end.difference(now);
  }

  TextRound copyWith({
    RoundPhase? phase,
    int? received,
    List<AudienceText>? picks,
    DateTime? deadline,
    bool? byAi,
  }) => TextRound(
    phase: phase ?? this.phase,
    received: received ?? this.received,
    picks: picks ?? this.picks,
    deadline: deadline ?? this.deadline,
    byAi: byAi ?? this.byAi,
  );

  static TextRound fromJson(Map<String, Object?> json, DateTime now) {
    final remaining = (json['remaining'] as num? ?? 0).toDouble();
    return TextRound(
      phase: switch (json['phase']) {
        'abierta' => RoundPhase.open,
        'eligiendo' => RoundPhase.choosing,
        'lista' => RoundPhase.ready,
        _ => RoundPhase.closed,
      },
      received: (json['received'] as num? ?? 0).toInt(),
      byAi: json['byAi'] as bool? ?? false,
      deadline: now.add(Duration(milliseconds: (remaining * 1000).round())),
      picks: [
        for (final pick in (json['picks'] as List? ?? const []))
          if (pick case final Map<String, Object?> map) AudienceText.fromPick(map),
      ],
    );
  }
}

/// Algo que escribió el público: una excusa o una pregunta.
@immutable
class AudienceText {
  const AudienceText({
    required this.id,
    required this.text,
    required this.author,
    this.votes = 0,
    this.approved = false,
    this.done = false,
  });

  final String id;
  final String text;

  /// El widget que le tocó a quien lo escribió («Expanded», «Padding»…).
  final String author;
  final int votes;
  final bool approved;

  /// Pregunta ya respondida.
  final bool done;

  /// El contrato de `GET /excusas`: `{id, texto, apodo}`.
  static AudienceText fromPick(Map<String, Object?> json) => AudienceText(
    id: '${json['id']}',
    text: json['texto'] as String? ?? '',
    author: json['apodo'] as String? ?? 'Widget',
    approved: true,
  );

  static AudienceText fromJson(Map<String, Object?> json) => AudienceText(
    id: json['id']! as String,
    text: json['text']! as String,
    author: json['author'] as String? ?? 'Widget',
    votes: (json['votes'] as num? ?? 0).toInt(),
    approved: json['approved'] as bool? ?? false,
    done: json['done'] as bool? ?? false,
  );
}
