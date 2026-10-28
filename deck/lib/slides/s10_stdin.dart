import 'package:material_ui/material_ui.dart';

import '../engine/deck_scope.dart';
import '../engine/slide.dart';
import '../live/join_card.dart';
import '../live/live_models.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/slide_scaffold.dart';
import 'sections.dart';

final stdinSlides = [
  Slide(
    id: 'preguntas',
    section: stdinSection,
    title: 'Preguntas',
    cue: (step) => const AudienceCue.questions(),
    builder: (context, step) => const _Questions(),
  ),
];

/// Las preguntas que el público mandó y apoyó. Solo salen las aprobadas en
/// la página de moderación.
class _Questions extends StatelessWidget {
  const _Questions();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    return SlideScaffold(
      title: 'stdin abierto: sus preguntas',
      lead: 'Las más apoyadas, arriba.',
      trailing: const JoinCard(qrSize: 170, compact: true),
      child: ListenableBuilder(
        listenable: live,
        builder: (context, _) {
          final questions = live.questions.take(5).toList();
          if (questions.isEmpty) {
            return Center(
              child: Text(
                live.online
                    ? 'Todavía no hay preguntas aprobadas. Escríbanlas en el celular.'
                    : 'Sin servidor: levanten la mano.',
                style: DeckType.headline.copyWith(color: colors.muted),
              ),
            );
          }
          return Column(
            children: [
              for (final question in questions)
                AnimatedOpacity(
                  duration: Motion.base,
                  opacity: question.done ? 0.38 : 1,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: Border.all(color: colors.line, width: Space.hairline),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 92,
                          child: Text(
                            '+${question.votes}',
                            style: DeckType.title.copyWith(
                              fontSize: 40,
                              color: colors.accentText,
                              fontFeatures: DeckType.tabular,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            question.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: DeckType.small.copyWith(fontSize: 30, color: colors.ink),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          '${question.author}()',
                          style: DeckType.monoSmall.copyWith(color: colors.faint),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
