import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../engine/overview.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';

enum TermTone { plain, muted, accent, success, warning, danger }

/// Una línea de terminal: un comando que se escribe o una salida que aparece.
///
/// En el texto, `[✓]`, `[!]` y `[✗]` al principio se pintan como en
/// `flutter doctor`, y `{fire}` es el fuego del hot reload.
@immutable
class TermLine {
  const TermLine(
    this.text, {
    this.tone = TermTone.plain,
    this.pause = const Duration(milliseconds: 90),
  }) : command = false;

  const TermLine.command(
    this.text, {
    this.pause = const Duration(milliseconds: 600),
  }) : command = true,
       tone = TermTone.plain;

  final String text;
  final bool command;
  final TermTone tone;

  /// La espera antes de que aparezca (o de que empiece a escribirse).
  final Duration pause;
}

class Terminal extends StatefulWidget {
  const Terminal({
    required this.lines,
    this.title = 'zsh',
    this.play = true,
    this.onDone,
    this.fontSize = 24,
    this.minLines = 0,
    super.key,
  });

  final List<TermLine> lines;
  final String title;

  /// Se reproduce sola al aparecer. Si no, se muestra completa.
  final bool play;
  final VoidCallback? onDone;
  final double fontSize;
  final int minLines;

  @override
  State<Terminal> createState() => _TerminalState();
}

class _TerminalState extends State<Terminal> {
  int _shown = 0;
  int _typed = 0;
  Timer? _timer;
  final _random = math.Random(7);

  bool get _done => _shown >= widget.lines.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || _shown > 0) return;
    if (!widget.play || Motion.reduced(context) || Thumbnail.of(context)) {
      _shown = widget.lines.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone?.call());
      return;
    }
    _schedule(widget.lines.first.pause);
  }

  void _schedule(Duration wait) => _timer = Timer(wait, _advance);

  void _advance() {
    if (!mounted || _done) return;
    final line = widget.lines[_shown];
    if (line.command && _typed < line.text.length) {
      setState(() => _typed++);
      // Escribe como una persona: a ratos más rápido, a ratos más lento.
      _schedule(Duration(milliseconds: 34 + _random.nextInt(46)));
      return;
    }
    setState(() {
      _shown++;
      _typed = 0;
    });
    if (_done) {
      widget.onDone?.call();
    } else {
      final next = widget.lines[_shown];
      _schedule(line.command ? next.pause + const Duration(milliseconds: 260) : next.pause);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = DeckType.mono.copyWith(
      fontSize: widget.fontSize,
      height: 1.45,
      color: CodeColors.plain,
    );
    final lineHeight = widget.fontSize * 1.45;
    final visible = [
      for (var index = 0; index < _shown; index++) _line(widget.lines[index], colors),
      if (!_done && widget.lines[_shown].command && _typed > 0)
        _command(widget.lines[_shown].text.substring(0, _typed), colors, typing: true),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CodeColors.background,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: CodeColors.border, width: Space.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: CodeColors.header,
              borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
              border: Border(bottom: BorderSide(color: CodeColors.border)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              widget.title,
              style: DeckType.monoSmall.copyWith(color: CodeColors.punctuation),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 18, 26, 22),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: widget.minLines * lineHeight),
              child: DefaultTextStyle(
                style: style,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...visible,
                    if (_done) _command('', colors, typing: false, idle: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _command(String text, DeckColors colors, {required bool typing, bool idle = false}) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: r'$ ', style: TextStyle(color: FlutterBrand.sky)),
          TextSpan(text: text),
          if (typing || idle) const WidgetSpan(child: _Caret()),
        ],
      ),
    );
  }

  Widget _line(TermLine line, DeckColors colors) {
    if (line.command) return _command(line.text, colors, typing: false);
    final color = switch (line.tone) {
      TermTone.plain => CodeColors.plain,
      TermTone.muted => CodeColors.comment,
      TermTone.accent => const Color(0xFF6FB7FF),
      TermTone.success => FlutterBrand.green,
      TermTone.warning => const Color(0xFFFFD25E),
      TermTone.danger => FlutterBrand.red,
    };
    return Text.rich(TextSpan(children: _spans(line.text, color)));
  }

  /// Pinta los marcadores de `flutter doctor` y el fuego con íconos: esas
  /// figuras no vienen en la fuente.
  List<InlineSpan> _spans(String text, Color color) {
    final spans = <InlineSpan>[];
    var rest = text;
    final mark = RegExp(r'^\[(✓|!|✗)\]').firstMatch(rest);
    if (mark != null) {
      final (icon, tint) = switch (mark[1]) {
        '✓' => (Icons.check, FlutterBrand.green),
        '!' => (Icons.priority_high, const Color(0xFFFFD25E)),
        _ => (Icons.close, FlutterBrand.red),
      };
      spans.addAll([
        TextSpan(text: '[', style: TextStyle(color: tint)),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(icon, size: widget.fontSize * 0.9, color: tint),
        ),
        TextSpan(text: '] ', style: TextStyle(color: tint)),
      ]);
      rest = rest.substring(mark[0]!.length).trimLeft();
    }
    // El fuego y las marcas sueltas (✓, ✗) tampoco vienen en la fuente.
    final icons = {
      '{fire}': (Icons.local_fire_department, const Color(0xFFFF8A3D)),
      '✓': (Icons.check, FlutterBrand.green),
      '✗': (Icons.close, FlutterBrand.red),
    };
    var cursor = 0;
    for (final match in RegExp(r'\{fire\}|✓|✗').allMatches(rest)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: rest.substring(cursor, match.start), style: TextStyle(color: color)));
      }
      final (icon, tint) = icons[match[0]]!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(icon, size: widget.fontSize, color: tint),
        ),
      );
      cursor = match.end;
    }
    if (cursor < rest.length) {
      spans.add(TextSpan(text: rest.substring(cursor), style: TextStyle(color: color)));
    }
    return spans;
  }
}

class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1060),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Thumbnail.of(context) || Motion.reduced(context)) {
      _blink.value = 0;
    } else if (!_blink.isAnimating) {
      _blink.repeat();
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blink,
      builder: (context, _) => Opacity(
        opacity: _blink.value < 0.55 ? 1 : 0,
        child: Text(
          '▍',
          style: DefaultTextStyle.of(context).style.copyWith(color: FlutterBrand.sky),
        ),
      ),
    );
  }
}
