import 'package:material_ui/material_ui.dart';

import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import 'reveal.dart';

/// Una frase grande, con una parte en el color de acento.
class Statement extends StatelessWidget {
  const Statement(
    this.text, {
    this.highlight,
    this.style,
    this.align = TextAlign.start,
    super.key,
  });

  final String text;

  /// El pedazo de [text] que va en azul.
  final String? highlight;
  final TextStyle? style;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = (style ?? DeckType.display).copyWith(color: colors.ink);
    final mark = highlight;
    if (mark == null || !text.contains(mark)) {
      return Text(text, style: base, textAlign: align);
    }
    final start = text.indexOf(mark);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(text: mark, style: TextStyle(color: colors.accentText)),
          TextSpan(text: text.substring(start + mark.length)),
        ],
      ),
      style: base,
      textAlign: align,
    );
  }
}

/// Una etiqueta pequeña en monoespaciada, como las de un IDE.
class Tag extends StatelessWidget {
  const Tag(this.label, {this.color, this.filled = false, super.key});

  final String label;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colors.accentText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? tint.withValues(alpha: 0.16) : null,
        border: Border.all(color: tint.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: DeckType.monoSmall.copyWith(color: tint)),
    );
  }
}

/// Una tarjeta con título, texto y, si hace falta, un ícono.
class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    this.body,
    this.icon,
    this.footer,
    this.accent,
    this.child,
    super.key,
  });

  final String title;
  final String? body;
  final IconData? icon;
  final String? footer;
  final Color? accent;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: accent ?? colors.line,
          width: accent == null ? Space.hairline : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 38, color: accent ?? colors.accentText),
            const SizedBox(height: 18),
          ],
          Text(
            title,
            style: DeckType.headline.copyWith(fontSize: 34, color: colors.ink),
          ),
          if (body != null) ...[
            const SizedBox(height: 12),
            Text(body!, style: DeckType.small.copyWith(color: colors.muted)),
          ],
          ?child,
          if (footer != null) ...[
            const Spacer(),
            Text(
              footer!,
              style: DeckType.monoSmall.copyWith(color: colors.faint),
            ),
          ],
        ],
      ),
    );
  }
}

/// Una lista numerada que aparece de a un punto por clic.
class PointList extends StatelessWidget {
  const PointList({
    required this.points,
    this.visible,
    this.gap = 26,
    this.style,
    super.key,
  });

  /// Título y, opcionalmente, una línea de detalle.
  final List<(String, String?)> points;

  /// Cuántos se ven. Nulo: todos.
  final int? visible;
  final double gap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, (title, detail)) in points.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: Reveal(
              visible: visible == null || index < visible!,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 76,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: DeckType.monoLabel.copyWith(color: colors.accentText),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: (style ?? DeckType.headline.copyWith(fontSize: 38))
                              .copyWith(color: colors.ink),
                        ),
                        if (detail != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              detail,
                              style: DeckType.small.copyWith(color: colors.muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Una tabla de equivalencias: la primera columna es el concepto.
class CompareTable extends StatelessWidget {
  const CompareTable({
    required this.headers,
    required this.rows,
    this.highlightColumn,
    this.mono = true,
    this.fontSize = 22,
    this.firstColumnFlex = 1.3,
    super.key,
  });

  final List<String> headers;
  final List<List<String>> rows;

  /// La columna que va en azul (la de Flutter, casi siempre).
  final int? highlightColumn;
  final bool mono;
  final double fontSize;
  final double firstColumnFlex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cell = (mono ? DeckType.mono : DeckType.small).copyWith(
      fontSize: fontSize,
      height: 1.3,
      color: colors.ink,
    );
    Widget row(List<String> cells, {bool header = false}) => Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, text) in cells.indexed)
            Expanded(
              flex: index == 0 ? (firstColumnFlex * 10).round() : 10,
              child: Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Text(
                  text,
                  style: header
                      ? DeckType.monoLabel.copyWith(
                          color: index == highlightColumn
                              ? colors.accentText
                              : colors.faint,
                        )
                      : index == 0
                      ? DeckType.small.copyWith(
                          fontSize: fontSize + 2,
                          color: colors.muted,
                        )
                      : cell.copyWith(
                          color: index == highlightColumn
                              ? colors.accentText
                              : colors.ink,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
    return Column(
      children: [
        row(headers, header: true),
        for (final cells in rows) row(cells),
      ],
    );
  }
}

/// Una barra de votación horizontal: etiqueta, barra y porcentaje.
class VoteBar extends StatelessWidget {
  const VoteBar({
    required this.label,
    required this.share,
    required this.votes,
    this.index,
    this.state = VoteBarState.open,
    this.height = 74,
    super.key,
  });

  final String label;
  final double share;
  final int votes;

  /// El número de la tecla de mano alzada.
  final int? index;
  final VoteBarState state;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (fill, border) = switch (state) {
      VoteBarState.open => (colors.accent.withValues(alpha: 0.28), colors.line),
      VoteBarState.correct => (colors.success.withValues(alpha: 0.3), colors.success),
      VoteBarState.wrong => (colors.line.withValues(alpha: 0.5), colors.line),
    };
    return AnimatedOpacity(
      duration: Motion.base,
      opacity: state == VoteBarState.wrong ? 0.45 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: border,
            width: state == VoteBarState.correct ? 2 : Space.hairline,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.sm),
          child: Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: share.clamp(0, 1)),
                duration: Motion.slow,
                curve: Motion.emphasized,
                builder: (context, value, _) => FractionallySizedBox(
                  widthFactor: value,
                  heightFactor: 1,
                  child: ColoredBox(color: fill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    if (index != null) ...[
                      Text(
                        '$index',
                        style: DeckType.monoSmall.copyWith(color: colors.faint),
                      ),
                      const SizedBox(width: 18),
                    ],
                    if (state == VoteBarState.correct) ...[
                      Icon(Icons.check_circle, color: colors.success, size: 30),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DeckType.small.copyWith(
                          fontSize: height > 60 ? 30 : 24,
                          color: colors.ink,
                        ),
                      ),
                    ),
                    Text(
                      '${(share * 100).round()} %',
                      style: DeckType.mono.copyWith(
                        color: colors.ink,
                        fontFeatures: DeckType.tabular,
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        '$votes',
                        textAlign: TextAlign.right,
                        style: DeckType.monoSmall.copyWith(
                          color: colors.faint,
                          fontFeatures: DeckType.tabular,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum VoteBarState { open, correct, wrong }

/// Pestañas que cambian con los clics: la misma idea en varios lenguajes.
class StepTabs extends StatelessWidget {
  const StepTabs({required this.labels, required this.selected, super.key});

  final List<String> labels;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (final (index, label) in labels.indexed)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedContainer(
              duration: Motion.base,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: index == selected ? colors.accent : colors.surface,
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border.all(
                  color: index == selected ? colors.accent : colors.line,
                ),
              ),
              child: Text(
                label,
                style: DeckType.monoLabel.copyWith(
                  color: index == selected ? Colors.white : colors.muted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
