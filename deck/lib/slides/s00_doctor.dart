import 'package:material_ui/material_ui.dart';

import '../engine/deck_scope.dart';
import '../engine/slide.dart';
import '../live/join_card.dart';
import '../live/live_models.dart';
import '../live/poll_view.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/slide_scaffold.dart';
import '../ui/terminal.dart';
import 'sections.dart';

const warmUpPoll = PollSpec(
  id: 'calentamiento',
  question: '¿Con qué haces apps (o software) hoy?',
  options: [
    PollOption('backend', 'Backend: Java o Kotlin'),
    PollOption('android', 'Android nativo'),
    PollOption('ios', 'iOS nativo (Swift)'),
    PollOption('web', 'Web: React, Angular, Vue…'),
    PollOption('rn', 'React Native'),
    PollOption('flutter', 'Ya uso Flutter'),
    PollOption('nada', 'Todavía no programo'),
  ],
);

final doctorSlides = [
  Slide(
    id: 'doctor',
    section: doctorSection,
    title: 'El doctor de la sala',
    builder: (context, step) => const _Doctor(),
  ),
  Slide(
    id: 'calentamiento',
    section: doctorSection,
    title: 'Calentamiento',
    cue: (step) => const AudienceCue.poll(warmUpPoll),
    builder: (context, step) => const _WarmUp(),
  ),
];

const _doctorLines = [
  TermLine.command('flutter doctor --sala'),
  TermLine('[✓] Proyector (1920 × 1080)', pause: Duration(milliseconds: 400)),
  TermLine('[✓] Café (dos tazas, mínimo)', pause: Duration(milliseconds: 260)),
  TermLine('[✓] Wi-Fi del auditorio (cruzando los dedos)', pause: Duration(milliseconds: 260)),
  TermLine(
    '[!] Tu celular todavía no está conectado',
    tone: TermTone.warning,
    pause: Duration(milliseconds: 420),
  ),
  TermLine('    → Escanea el QR y escribe tu nombre', tone: TermTone.warning),
  TermLine.command('flutter logs --sala', pause: Duration(milliseconds: 700)),
];

/// Cada persona que escribe su nombre aparece en la terminal, con el widget
/// que le tocó de apodo.
List<TermLine> _arrivalLines(List<Arrival> arrivals) => [
  for (final arrival in arrivals)
    TermLine(
      '[✓] Llegó ${arrival.name} → ${arrival.widget}()',
      id: arrival.number,
    ),
];

/// Mientras la gente llega: el doctor de la sala y el QR, grande.
class _Doctor extends StatelessWidget {
  const _Doctor();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    return SlideScaffold(
      title: 'Antes de empezar, un chequeo',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: live,
              builder: (context, _) => Terminal(
                lines: _doctorLines,
                extra: _arrivalLines(live.arrivals),
                title: 'zsh · auditorio',
                minLines: 15,
                maxLines: 15,
              ),
            ),
          ),
          const SizedBox(width: 64),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const JoinCard(qrSize: 420, compact: true),
              const SizedBox(height: 40),
              SizedBox(
                width: 660,
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Escribe tu nombre y te toca un widget: '),
                      TextSpan(
                        text: 'ese es tu apodo de hoy.',
                        style: TextStyle(color: colors.accentText),
                      ),
                    ],
                  ),
                  style: DeckType.body.copyWith(color: colors.muted),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.qr_code_2, color: colors.faint, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Un solo escaneo sirve para toda la charla.',
                    style: DeckType.small.copyWith(color: colors.faint),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarmUp extends StatelessWidget {
  const _WarmUp();

  @override
  Widget build(BuildContext context) {
    return SlideScaffold(
      title: '¿Con qué haces software hoy?',
      lead: 'Para saber a quién le estoy hablando.',
      trailing: const JoinCard(qrSize: 200, compact: true),
      child: const SizedBox(
        width: 1180,
        child: PollView(poll: warmUpPoll, barHeight: 58, gap: 10),
      ),
    );
  }
}
