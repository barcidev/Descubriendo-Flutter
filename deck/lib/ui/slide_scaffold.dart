import 'dart:async';

import 'package:flutter/widgets.dart';

import '../engine/overview.dart';
import '../engine/slide_info.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';

/// La estructura de casi todas las diapositivas: el comando de la sección,
/// un título, una entradilla opcional y el contenido.
class SlideScaffold extends StatelessWidget {
  const SlideScaffold({
    required this.child,
    this.title,
    this.lead,
    this.trailing,
    super.key,
  });

  final String? title;
  final String? lead;

  /// Algo a la derecha del título (un QR, una cifra).
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.pageX,
        Space.pageTop - 24,
        Space.pageX,
        Space.pageBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionChip(),
          const SizedBox(height: 26),
          if (title != null || trailing != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(title!, style: DeckType.title.copyWith(color: colors.ink)),
                      if (lead != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          lead!,
                          style: DeckType.headline.copyWith(
                            fontSize: 34,
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: Space.xl),
                  trailing!,
                ],
              ],
            ),
          const SizedBox(height: 40),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// El comando de la sección, como una línea de terminal. En la primera
/// diapositiva de cada sección se escribe solo.
class SectionChip extends StatelessWidget {
  const SectionChip({super.key});

  @override
  Widget build(BuildContext context) {
    final info = SlideInfo.maybeOf(context);
    if (info == null) return const SizedBox.shrink();
    final colors = context.colors;
    final section = info.slide.section;
    return DefaultTextStyle(
      style: DeckType.monoLabel.copyWith(color: colors.faint),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(r'$ ', style: TextStyle(color: colors.faint)),
          TypeOn(
            text: section.command,
            animate: info.startsSection,
            style: TextStyle(color: colors.accentText),
          ),
          Text('   # ${section.subtitle}'),
        ],
      ),
    );
  }
}

/// Texto que se escribe letra por letra, con un cursor de bloque.
class TypeOn extends StatefulWidget {
  const TypeOn({
    required this.text,
    this.animate = true,
    this.style,
    this.delay = const Duration(milliseconds: 520),
    this.perCharacter = const Duration(milliseconds: 42),
    super.key,
  });

  final String text;
  final bool animate;
  final TextStyle? style;
  final Duration delay;
  final Duration perCharacter;

  @override
  State<TypeOn> createState() => _TypeOnState();
}

class _TypeOnState extends State<TypeOn> {
  int _shown = 0;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || _shown > 0) return;
    if (!widget.animate || Motion.reduced(context) || Thumbnail.of(context)) {
      _shown = widget.text.length;
      return;
    }
    _timer = Timer(widget.delay, _tick);
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _shown++);
    if (_shown < widget.text.length) {
      _timer = Timer(widget.perCharacter, _tick);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typing = _shown < widget.text.length;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: widget.text.substring(0, _shown)),
          if (typing) const TextSpan(text: '▍'),
        ],
      ),
      style: widget.style,
    );
  }
}
