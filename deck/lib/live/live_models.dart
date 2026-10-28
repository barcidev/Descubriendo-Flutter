import 'package:flutter/foundation.dart';

/// Lo que ve el celular del público en cada momento.
enum AudienceMode { idle, poll, counter, excuse, questions, rating }

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

  const AudienceCue.excuse() : this._(AudienceMode.excuse);

  const AudienceCue.questions() : this._(AudienceMode.questions);

  const AudienceCue.rating() : this._(AudienceMode.rating);

  const AudienceCue._(
    this.mode, {
    this.poll,
    this.open = false,
    this.revealed = false,
  });

  final AudienceMode mode;
  final PollSpec? poll;

  /// La votación recibe votos.
  final bool open;

  /// Ya se mostró la respuesta: los celulares también la ven.
  final bool revealed;

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    if (poll != null) 'poll': poll!.toJson(),
    'open': open,
    'revealed': revealed,
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

  static AudienceText fromJson(Map<String, Object?> json) => AudienceText(
    id: json['id']! as String,
    text: json['text']! as String,
    author: json['author'] as String? ?? 'Widget',
    votes: (json['votes'] as num? ?? 0).toInt(),
    approved: json['approved'] as bool? ?? false,
    done: json['done'] as bool? ?? false,
  );
}
