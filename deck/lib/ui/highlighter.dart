/// Resaltado de sintaxis hecho a mano, línea por línea. No pretende ser un
/// compilador: le basta con que el código de las diapositivas se vea como
/// en el editor.
library;

enum CodeLang {
  dart('Dart'),
  kotlin('Kotlin'),
  swift('Swift'),
  typescript('TypeScript'),
  jsx('JSX'),
  yaml('YAML'),
  bash('Terminal'),
  plain('Texto');

  const CodeLang(this.label);

  final String label;
}

enum TokenKind {
  plain,
  keyword,
  type,
  string,
  number,
  comment,
  annotation,
  function,
  punctuation,
}

class CodeToken {
  const CodeToken(this.text, this.kind);

  final String text;
  final TokenKind kind;

  @override
  String toString() => '${kind.name}($text)';
}

const _dart = {
  'abstract', 'as', 'assert', 'async', 'await', 'base', 'break', 'case', //
  'catch', 'class', 'const', 'continue', 'default', 'do', 'else', 'enum',
  'extends', 'extension', 'external', 'factory', 'false', 'final',
  'finally', 'for', 'get', 'if', 'implements', 'import', 'in', 'interface',
  'is', 'late', 'library', 'mixin', 'new', 'null', 'on', 'operator',
  'part', 'required', 'rethrow', 'return', 'sealed', 'set', 'static',
  'super', 'switch', 'sync', 'this', 'throw', 'true', 'try', 'typedef',
  'var', 'void', 'when', 'while', 'with', 'yield',
};

const _kotlin = {
  'as', 'break', 'class', 'continue', 'data', 'do', 'else', 'enum', //
  'false', 'for', 'fun', 'if', 'import', 'in', 'interface', 'is', 'null',
  'object', 'override', 'package', 'private', 'return', 'sealed',
  'suspend', 'this', 'true', 'val', 'var', 'when', 'while',
};

const _swift = {
  'as', 'async', 'await', 'break', 'case', 'class', 'continue', 'default', //
  'else', 'enum', 'extension', 'false', 'for', 'func', 'guard', 'if',
  'import', 'in', 'let', 'nil', 'private', 'protocol', 'return', 'self',
  'some', 'static', 'struct', 'switch', 'throws', 'true', 'try', 'var',
  'where', 'while',
};

const _typescript = {
  'as', 'async', 'await', 'break', 'case', 'class', 'const', 'continue', //
  'default', 'else', 'export', 'extends', 'false', 'for', 'from',
  'function', 'if', 'import', 'in', 'interface', 'let', 'new', 'null',
  'of', 'return', 'switch', 'this', 'throw', 'true', 'try', 'type',
  'undefined', 'var', 'while',
};

Set<String> _keywordsOf(CodeLang lang) => switch (lang) {
  CodeLang.dart => _dart,
  CodeLang.kotlin => _kotlin,
  CodeLang.swift => _swift,
  CodeLang.typescript || CodeLang.jsx => _typescript,
  _ => const {},
};

final _cLike = RegExp(
  r'(?<comment>//.*$)'
  r"|(?<string>'(?:[^'\\]|\\.)*'"
  r'|"(?:[^"\\]|\\.)*"'
  r'|`(?:[^`\\]|\\.)*`)'
  r'|(?<annotation>@[A-Za-z_]\w*)'
  r'|(?<number>\b\d[\d_]*(?:\.\d+)?\b)'
  r'|(?<word>[A-Za-z_$][\w$]*)'
  r'|(?<space>\s+)'
  r'|(?<other>.)',
);

final _hashComment = RegExp(
  r'(?<comment>#.*$)'
  r"|(?<string>'(?:[^'\\]|\\.)*'"
  r'|"(?:[^"\\]|\\.)*")'
  r'|(?<number>\b\d[\d_.]*\b)'
  r'|(?<word>[A-Za-z_$][\w$\-./]*)'
  r'|(?<flag>--?[\w\-]+)'
  r'|(?<space>\s+)'
  r'|(?<other>.)',
);

final _yamlKey = RegExp(r'^(\s*-?\s*)([\w\-./]+)(:)');

const _punctuation = '{}()[];,.:=<>+-*/!?&|%^~';

List<CodeToken> highlightLine(String line, CodeLang lang) {
  switch (lang) {
    case CodeLang.plain:
      return [CodeToken(line, TokenKind.plain)];
    case CodeLang.yaml:
      return _yaml(line);
    case CodeLang.bash:
      return _bash(line);
    default:
      return _code(line, lang);
  }
}

List<CodeToken> _code(String line, CodeLang lang) {
  final keywords = _keywordsOf(lang);
  final tokens = <CodeToken>[];
  final matches = _cLike.allMatches(line).toList();
  for (final (index, match) in matches.indexed) {
    final text = match[0]!;
    final kind = switch (match) {
      _ when match.namedGroup('comment') != null => TokenKind.comment,
      _ when match.namedGroup('string') != null => TokenKind.string,
      _ when match.namedGroup('annotation') != null => TokenKind.annotation,
      _ when match.namedGroup('number') != null => TokenKind.number,
      _ when match.namedGroup('word') != null => _word(
        text,
        keywords,
        lang,
        previous: _previousSignificant(matches, index),
        next: _nextSignificant(matches, index),
      ),
      _ when match.namedGroup('other') != null =>
        _punctuation.contains(text) ? TokenKind.punctuation : TokenKind.plain,
      _ => TokenKind.plain,
    };
    _push(tokens, text, kind);
  }
  return tokens;
}

TokenKind _word(
  String word,
  Set<String> keywords,
  CodeLang lang, {
  required String? previous,
  required String? next,
}) {
  if (keywords.contains(word)) return TokenKind.keyword;
  // Etiquetas de JSX en minúscula: <div>, </span>.
  if (lang == CodeLang.jsx && (previous == '<' || previous == '/')) {
    return word.startsWith(RegExp('[A-Z]')) ? TokenKind.type : TokenKind.keyword;
  }
  if (word.startsWith(RegExp('[A-Z]'))) return TokenKind.type;
  if (next == '(') return TokenKind.function;
  return TokenKind.plain;
}

String? _previousSignificant(List<RegExpMatch> matches, int index) {
  for (var i = index - 1; i >= 0; i--) {
    if (matches[i].namedGroup('space') == null) return matches[i][0];
  }
  return null;
}

String? _nextSignificant(List<RegExpMatch> matches, int index) {
  for (var i = index + 1; i < matches.length; i++) {
    if (matches[i].namedGroup('space') == null) return matches[i][0];
  }
  return null;
}

List<CodeToken> _yaml(String line) {
  final key = _yamlKey.firstMatch(line);
  if (key == null) return _hashed(line, firstWordIsCommand: false);
  return [
    CodeToken(key[1]!, TokenKind.punctuation),
    CodeToken(key[2]!, TokenKind.type),
    CodeToken(key[3]!, TokenKind.punctuation),
    ..._hashed(line.substring(key[0]!.length), firstWordIsCommand: false),
  ];
}

List<CodeToken> _bash(String line) {
  // El prompt va aparte: «$ flutter create».
  if (line.startsWith(r'$ ')) {
    return [
      const CodeToken(r'$ ', TokenKind.comment),
      ..._hashed(line.substring(2), firstWordIsCommand: true),
    ];
  }
  return _hashed(line, firstWordIsCommand: true);
}

List<CodeToken> _hashed(String line, {required bool firstWordIsCommand}) {
  final tokens = <CodeToken>[];
  var sawWord = false;
  for (final match in _hashComment.allMatches(line)) {
    final text = match[0]!;
    TokenKind kind;
    if (match.namedGroup('comment') != null) {
      kind = TokenKind.comment;
    } else if (match.namedGroup('string') != null) {
      kind = TokenKind.string;
    } else if (match.namedGroup('number') != null) {
      kind = TokenKind.number;
    } else if (match.namedGroup('flag') != null) {
      kind = TokenKind.keyword;
    } else if (match.namedGroup('word') != null) {
      kind = firstWordIsCommand && !sawWord ? TokenKind.function : TokenKind.plain;
      sawWord = true;
    } else if (match.namedGroup('other') != null) {
      kind = _punctuation.contains(text) ? TokenKind.punctuation : TokenKind.plain;
    } else {
      kind = TokenKind.plain;
    }
    _push(tokens, text, kind);
  }
  return tokens;
}

/// Junta los pedazos seguidos del mismo tipo: menos spans que pintar.
void _push(List<CodeToken> tokens, String text, TokenKind kind) {
  if (tokens.isNotEmpty && tokens.last.kind == kind) {
    tokens[tokens.length - 1] = CodeToken(tokens.last.text + text, kind);
  } else {
    tokens.add(CodeToken(text, kind));
  }
}
