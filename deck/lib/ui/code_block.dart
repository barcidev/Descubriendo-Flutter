import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../engine/overview.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import 'highlighter.dart';

/// Un editor de código para diapositivas.
///
/// Cuando [code] cambia entre pasos, cada línea que sigue existiendo se
/// desliza a su nueva posición (y a su nueva sangría), las nuevas aparecen
/// y las que sobran se desvanecen: así se ve qué cambió y qué no.
class CodeBlock extends StatefulWidget {
  const CodeBlock({
    required this.code,
    this.language = CodeLang.dart,
    this.fileName,
    this.focus = const {},
    this.fontSize = 26,
    this.minLines = 0,
    this.footer,
    super.key,
  });

  final String code;
  final CodeLang language;
  final String? fileName;

  /// Líneas resaltadas, contando desde 1. Las demás se atenúan. Vacío: nada
  /// se atenúa.
  final Set<int> focus;
  final double fontSize;

  /// Alto mínimo, en líneas, para que el bloque no salte de tamaño.
  final int minLines;

  /// Una línea debajo del código, como la salida del analizador.
  final Widget? footer;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _Line {
  const _Line(this.key, this.indent, this.tokens);

  final String key;
  final int indent;
  final List<CodeToken> tokens;
}

List<_Line> _parse(String code, CodeLang language) {
  final raw = code.trimRight().split('\n');
  final seen = <String, int>{};
  return [
    for (final source in raw)
      () {
        final text = source.trimLeft();
        final occurrence = seen.update(text, (n) => n + 1, ifAbsent: () => 0);
        return _Line(
          '$text#$occurrence',
          source.length - text.length,
          highlightLine(text, language),
        );
      }(),
  ];
}

class _CodeBlockState extends State<CodeBlock> {
  late List<_Line> _lines = _parse(widget.code, widget.language);
  List<(_Line, int)> _leaving = const [];
  Set<String> _entering = const {};

  @override
  void didUpdateWidget(CodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code == widget.code && oldWidget.language == widget.language) {
      return;
    }
    final next = _parse(widget.code, widget.language);
    final nextKeys = {for (final line in next) line.key};
    final oldKeys = {for (final line in _lines) line.key};
    _leaving = [
      for (final (index, line) in _lines.indexed)
        if (!nextKeys.contains(line.key)) (line, index),
    ];
    _entering = {
      for (final line in next)
        if (!oldKeys.contains(line.key)) line.key,
    };
    _lines = next;
  }

  @override
  Widget build(BuildContext context) {
    final instant = Motion.reduced(context) || Thumbnail.of(context);
    final move = instant ? Duration.zero : Motion.slow;
    final style = DeckType.code.copyWith(fontSize: widget.fontSize);
    final lineHeight = widget.fontSize * (style.height ?? 1.5);
    final charWidth = _charWidth(style);
    final lines = math.max(_lines.length, widget.minLines);
    final digits = '${_lines.length}'.length;
    final gutter = digits * charWidth + 40;
    const padding = 18.0;
    final focused = widget.focus.isNotEmpty;

    Widget text(_Line line) => Text.rich(
      TextSpan(
        children: [
          for (final token in line.tokens)
            TextSpan(text: token.text, style: _styleOf(token.kind)),
        ],
      ),
      style: style,
      softWrap: false,
    );

    double top(int index) => padding + index * lineHeight;
    double left(_Line line) => gutter + line.indent * charWidth;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: CodeColors.background,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: CodeColors.border, width: Space.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(fileName: widget.fileName, language: widget.language),
            AnimatedContainer(
              duration: move,
              curve: Motion.emphasized,
              height: lines * lineHeight + padding * 2,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final (index, range) in _ranges(widget.focus).indexed)
                    AnimatedPositioned(
                      key: ValueKey('focus-$index'),
                      duration: move,
                      curve: Motion.emphasized,
                      left: 0,
                      right: 0,
                      top: top(range.$1 - 1),
                      height: (range.$2 - range.$1 + 1) * lineHeight,
                      child: const _FocusBar(),
                    ),
                  for (var index = 0; index < _lines.length; index++)
                    Positioned(
                      key: ValueKey('n$index'),
                      left: 0,
                      width: gutter - 22,
                      top: top(index),
                      height: lineHeight,
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.right,
                        style: style.copyWith(
                          color: CodeColors.lineNumber,
                          fontFeatures: DeckType.tabular,
                        ),
                      ),
                    ),
                  for (final (line, index) in _leaving)
                    Positioned(
                      key: ValueKey('out-${line.key}'),
                      left: left(line),
                      top: top(index),
                      child: _Fade(out: true, duration: move, child: text(line)),
                    ),
                  for (final (index, line) in _lines.indexed)
                    AnimatedPositioned(
                      key: ValueKey(line.key),
                      duration: move,
                      curve: Motion.emphasized,
                      left: left(line),
                      top: top(index),
                      height: lineHeight,
                      child: AnimatedOpacity(
                        duration: instant ? Duration.zero : Motion.base,
                        opacity: !focused || widget.focus.contains(index + 1)
                            ? 1
                            : 0.34,
                        child: _entering.contains(line.key) && !instant
                            ? _Fade(out: false, duration: move, child: text(line))
                            : text(line),
                      ),
                    ),
                ],
              ),
            ),
            ?widget.footer,
          ],
        ),
      ),
    );
  }

  static double _charWidth(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: 'M' * 20, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width / 20;
  }

  /// Las líneas enfocadas, agrupadas en tramos seguidos.
  static List<(int, int)> _ranges(Set<int> focus) {
    final sorted = focus.toList()..sort();
    final ranges = <(int, int)>[];
    for (final line in sorted) {
      if (ranges.isNotEmpty && ranges.last.$2 == line - 1) {
        ranges[ranges.length - 1] = (ranges.last.$1, line);
      } else {
        ranges.add((line, line));
      }
    }
    return ranges;
  }
}

TextStyle _styleOf(TokenKind kind) => switch (kind) {
  TokenKind.plain => const TextStyle(color: CodeColors.plain),
  TokenKind.keyword => const TextStyle(color: CodeColors.keyword),
  TokenKind.type => const TextStyle(color: CodeColors.type),
  TokenKind.string => const TextStyle(color: CodeColors.string),
  TokenKind.number => const TextStyle(color: CodeColors.number),
  TokenKind.comment => const TextStyle(
    color: CodeColors.comment,
    fontStyle: FontStyle.italic,
  ),
  TokenKind.annotation => const TextStyle(color: CodeColors.annotation),
  TokenKind.function => const TextStyle(color: CodeColors.function),
  TokenKind.punctuation => const TextStyle(color: CodeColors.punctuation),
};

class _Header extends StatelessWidget {
  const _Header({required this.fileName, required this.language});

  final String? fileName;
  final CodeLang language;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: DeckFonts.mono,
      fontSize: 17,
      height: 1.2,
      color: Color(0xFF8297BA),
    );
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: CodeColors.header,
        border: Border(bottom: BorderSide(color: CodeColors.border)),
      ),
      child: Row(
        children: [
          // Una pestaña, como la del editor: el archivo abierto.
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: FlutterBrand.sky,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(fileName ?? 'sin_titulo.${_extension(language)}', style: style),
          const Spacer(),
          Text(language.label, style: style.copyWith(color: CodeColors.lineNumber)),
        ],
      ),
    );
  }

  static String _extension(CodeLang language) => switch (language) {
    CodeLang.dart => 'dart',
    CodeLang.kotlin => 'kt',
    CodeLang.swift => 'swift',
    CodeLang.typescript => 'ts',
    CodeLang.jsx => 'jsx',
    CodeLang.yaml => 'yaml',
    CodeLang.bash => 'sh',
    CodeLang.plain => 'txt',
  };
}

class _FocusBar extends StatelessWidget {
  const _FocusBar();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: CodeColors.focus,
        border: Border(left: BorderSide(color: FlutterBrand.sky, width: 4)),
      ),
    );
  }
}

/// Aparece (o se desvanece) una sola vez al construirse.
class _Fade extends StatefulWidget {
  const _Fade({required this.out, required this.duration, required this.child});

  final bool out;
  final Duration duration;
  final Widget child;

  @override
  State<_Fade> createState() => _FadeState();
}

class _FadeState extends State<_Fade> {
  late bool _start = !widget.out;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _start = widget.out);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lo nuevo entra cuando lo que se movía ya llegó a su lugar.
    final hidden = _start;
    return AnimatedOpacity(
      opacity: hidden ? 0 : 1,
      duration: widget.duration * 0.7,
      curve: widget.out ? Curves.easeOut : const Interval(0.35, 1),
      child: AnimatedSlide(
        offset: hidden && !widget.out ? const Offset(0.02, 0) : Offset.zero,
        duration: widget.duration,
        curve: Motion.emphasized,
        child: widget.child,
      ),
    );
  }
}
