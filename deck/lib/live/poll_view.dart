import 'package:flutter/widgets.dart';

import '../engine/deck_scope.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/blocks.dart';
import 'live_models.dart';

/// Una votación en barras horizontales, con los votos en vivo. Al revelar,
/// la respuesta correcta se marca y las demás se apagan.
class PollView extends StatelessWidget {
  const PollView({
    required this.poll,
    this.revealed = false,
    this.barHeight = 74,
    this.gap = 14,
    super.key,
  });

  final PollSpec poll;
  final bool revealed;
  final double barHeight;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final live = DeckScope.of(context).live;
    final colors = context.colors;
    final graded = poll.options.any((option) => option.correct);
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) {
        final results = live.resultsFor(poll.id);
        final manual = !live.online && !live.simulating;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, option) in poll.options.indexed) ...[
              VoteBar(
                label: option.label,
                share: results.shareOf(option.id),
                votes: results.countOf(option.id),
                index: manual ? index + 1 : null,
                height: barHeight,
                state: !revealed || !graded
                    ? VoteBarState.open
                    : option.correct
                    ? VoteBarState.correct
                    : VoteBarState.wrong,
              ),
              SizedBox(height: gap),
            ],
            Text(
              manual
                  ? 'Mano alzada: teclas 1–${poll.options.length} suman votos'
                  : results.voters == 1
                  ? '1 persona votó'
                  : '${results.voters} personas votaron',
              style: DeckType.monoSmall.copyWith(color: colors.faint),
            ),
          ],
        );
      },
    );
  }
}
