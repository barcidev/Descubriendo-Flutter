import 'package:deck/engine/browser.dart';
import 'package:deck/engine/deck_controller.dart';
import 'package:deck/engine/slide.dart';
import 'package:deck/live/live_config.dart';
import 'package:deck/slides/slides.dart';
import 'package:deck/ui/highlighter.dart';
import 'package:deck/ui/qr_code.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _section = Section(command: 'q', subtitle: 'Prueba', minutes: 1);

Slide _slide(String id, {int steps = 1}) => Slide(
  id: id,
  section: _section,
  title: id,
  steps: steps,
  builder: (context, step) => const SizedBox(),
);

/// Un navegador de mentira con la URL que se le pida.
class _Browser implements Browser {
  _Browser(String url) : uri = Uri.parse(url);

  @override
  final Uri uri;
  final storage = <String, String>{};

  @override
  void replaceHash(String hash) {}

  @override
  void toggleFullscreen() {}

  @override
  String? read(String key) => storage[key];

  @override
  void write(String key, String value) => storage[key] = value;

  @override
  void openWindow(String url, String name) {}

  @override
  MessageChannel channel(String name) => throw UnimplementedError();
}

void main() {
  group('DeckController', () {
    test('avanza por los pasos antes de cambiar de diapositiva', () {
      final deck = DeckController([_slide('a', steps: 2), _slide('b')]);
      deck.next();
      expect((deck.index, deck.step), (0, 1));
      deck.next();
      expect((deck.index, deck.step), (1, 0));
      deck.next();
      expect((deck.index, deck.step), (1, 0), reason: 'la última no se pasa');
      deck.previous();
      expect((deck.index, deck.step), (0, 1), reason: 'al volver llega al último paso');
    });

    test('la pausa se quita con cualquier tecla de avance', () {
      final deck = DeckController([_slide('a'), _slide('b')])..togglePause();
      deck.next();
      expect(deck.paused, isFalse);
      expect(deck.index, 0);
    });

    test('la URL guarda la posición, contando desde 1', () {
      final deck = DeckController([_slide('a'), _slide('b', steps: 3)])
        ..goTo(1, step: 2);
      expect(deck.hash, '/2/3');
      expect(DeckController.parseHash('/2/3'), (1, 2));
      expect(DeckController.parseHash('/5'), (4, 0));
      expect(DeckController.parseHash('presentador'), isNull);
    });

    test('las secciones salen en orden y sin repetir', () {
      final deck = DeckController(buildDeck());
      expect(deck.sections.first.command, 'flutter doctor');
      expect(deck.sections.last.command, 'q');
      expect(deck.sections.toSet(), hasLength(deck.sections.length));
    });
  });

  test('la charla dura 45 minutos', () {
    final minutes = DeckController(buildDeck()).sections.fold(
      0,
      (total, section) => total + section.minutes,
    );
    expect(minutes, 45);
  });

  test('cada diapositiva tiene un id único (las notas del guion dependen de él)', () {
    final ids = [for (final slide in buildDeck()) slide.id];
    expect(ids.toSet(), hasLength(ids.length));
  });

  group('resaltado', () {
    List<TokenKind> kinds(String line, CodeLang lang) => [
      for (final token in highlightLine(line, lang))
        if (token.text.trim().isNotEmpty) token.kind,
    ];

    test('Dart: palabras clave, tipos, cadenas y llamadas', () {
      expect(kinds("final texto = Text('hola');", CodeLang.dart), [
        TokenKind.keyword,
        TokenKind.plain,
        TokenKind.punctuation,
        TokenKind.type,
        TokenKind.punctuation,
        TokenKind.string,
        TokenKind.punctuation,
      ]);
    });

    test('los comentarios se comen el resto de la línea', () {
      final tokens = highlightLine('excusa!; // confía en mí', CodeLang.dart);
      expect(tokens.last.kind, TokenKind.comment);
      expect(tokens.last.text, '// confía en mí');
    });

    test('bash: el primer comando y las banderas', () {
      // Los pedazos seguidos del mismo tipo se juntan: «build web» es uno.
      expect(kinds(r'$ flutter build web --wasm', CodeLang.bash), [
        TokenKind.comment,
        TokenKind.function,
        TokenKind.plain,
        TokenKind.keyword,
      ]);
    });
  });

  test('el QR de una URL sin ruta va en modo alfanumérico: menos módulos', () {
    const url = 'https://flutter-baq.onrender.com';
    final alphanumeric = encodeQr(url);
    final withPath = encodeQr('$url/a');
    expect(alphanumeric.moduleCount, lessThan(withPath.moduleCount));
    expect(alphanumeric.moduleCount, 25, reason: 'versión 2 del QR');
  });

  group('LiveConfig', () {
    test('toma el servidor y el token de la URL y los recuerda', () {
      final browser = _Browser(
        'http://127.0.0.1:8090/?servidor=https://flutter-baq.onrender.com&token=secreto#/1/1',
      );
      final config = LiveConfig.resolve(browser);
      expect(config.joinUrl, 'https://flutter-baq.onrender.com');
      expect(config.socket.toString(), 'wss://flutter-baq.onrender.com/ws?rol=presentador&token=secreto');
      expect(browser.storage['charla.token'], 'secreto');
    });

    test('servida en /deck/, usa su propio origen', () {
      final config = LiveConfig.resolve(_Browser('https://flutter-baq.onrender.com/deck/#/3/1'));
      expect(config.joinUrl, 'https://flutter-baq.onrender.com');
    });

    test('?servidor= vacío deja la charla en mano alzada', () {
      final browser = _Browser('http://127.0.0.1:8090/?servidor=#/1/1')
        ..storage['charla.servidor'] = 'https://viejo.onrender.com';
      expect(LiveConfig.resolve(browser).enabled, isFalse);
    });
  });
}
