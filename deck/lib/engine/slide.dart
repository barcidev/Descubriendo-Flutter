import 'package:flutter/widgets.dart';

import '../live/live_models.dart';

/// Una parte de la charla: un comando real de Flutter y lo que significa en
/// palabras sencillas.
@immutable
class Section {
  const Section({
    required this.command,
    required this.subtitle,
    required this.minutes,
  });

  final String command;
  final String subtitle;

  /// Cuánto tiempo le toca en el guion.
  final int minutes;
}

typedef SlideBuilder = Widget Function(BuildContext context, int step);

@immutable
class Slide {
  const Slide({
    required this.id,
    required this.section,
    required this.title,
    required this.builder,
    this.steps = 1,
    this.skippable = false,
    this.chrome = true,
    this.cue,
  });

  /// Nombre estable: lo usan las notas del guion y la vista del presentador.
  final String id;
  final Section section;

  /// Cómo se llama en la vista general y en la del presentador.
  final String title;
  final SlideBuilder builder;

  /// Cuántos clics tiene antes de pasar a la siguiente.
  final int steps;

  /// Se puede saltar si el tiempo no alcanza.
  final bool skippable;

  /// Muestra la barra de estado. Las de pantalla completa la esconden.
  final bool chrome;

  /// Lo que muestran los celulares en cada paso.
  final AudienceCue Function(int step)? cue;

  AudienceCue cueAt(int step) => cue?.call(step) ?? const AudienceCue.idle();
}
