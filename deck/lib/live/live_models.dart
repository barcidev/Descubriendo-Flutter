import 'package:flutter/foundation.dart';

/// Lo que ve el celular del público en cada momento.
enum AudienceMode { idle, poll, counter, excuse, questions, rating, credits }

@immutable
class PollOption {
  const PollOption(this.id, this.label, {this.detail, this.correct = false});

  final String id;
  final String label;

  /// Una línea de contexto que la diapositiva muestra al revelar.
  final String? detail;
  final bool correct;

  Map<String, Object?> toJson() => {'id': id, 'label': label};
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

  const AudienceCue._(
    this.mode, {
    this.poll,
    this.open = false,
    this.revealed = false,
    this.seconds,
  });

  final AudienceMode mode;
  final PollSpec? poll;

  /// La votación recibe votos.
  final bool open;

  /// Ya se mostró la respuesta: los celulares también la ven.
  final bool revealed;

  /// Cuánto dura la ronda de excusas.
  final int? seconds;

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    if (poll != null) 'poll': poll!.toJson(),
    'open': open,
    'revealed': revealed,
    if (seconds != null) 'seconds': seconds,
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
      other.revealed == revealed;

  @override
  int get hashCode => Object.hash(mode, poll?.id, open, revealed);
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
