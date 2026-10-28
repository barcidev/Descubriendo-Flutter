// Capturas de cada diapositiva, con las fuentes reales, para revisar el
// diseño sin abrir el navegador. Se corre a propósito:
//
//   fvm flutter test tool/capturas_test.dart
//
// Escribe un PNG por diapositiva (en su último paso) en build/capturas/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:deck/app.dart';
import 'package:deck/engine/browser.dart';
import 'package:deck/engine/deck_shell.dart';
import 'package:deck/engine/stage.dart';
import 'package:deck/live/live_config.dart';
import 'package:deck/live/live_controller.dart';
import 'package:deck/live/presenter_login.dart';
import 'package:deck/theme/deck_theme.dart';
import 'package:deck/slides/slides.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _out = Directory('build/capturas');

/// Diapositivas que se capturan en cada paso, no solo en el último.
const _everyStep = {
  'agenda',
  'pantalla-roja',
  'hecha-con-flutter',
  'excusometro-en-vivo',
  'hot-reload',
  'publicar',
};

/// Cuánto esperar (en tiempo de mentira) antes de la captura, si no basta
/// con lo normal: la terminal de la demo tarda en «compilar».
const _longer = {'doctor': 12000, 'demo': 9000, 'creditos': 4000};

/// Esperas en tiempo real: estas diapositivas miden con el reloj de verdad.
const _realWait = {'excusometro-en-vivo': 3600, 'preguntas': 10500};

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  await load('GoogleSansFlex', ['assets/fonts/GoogleSansFlex.ttf']);
  await load('GoogleSansCode', [
    'assets/fonts/GoogleSansCode.ttf',
    'assets/fonts/GoogleSansCode-Italic.ttf',
  ]);
  await load('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

/// Guarda la pantalla entera, como un golden.
Future<void> _shot(WidgetTester tester, String name) async {
  var boundary = tester.renderObject(find.byType(MaterialApp).first);
  while (!boundary.isRepaintBoundary) {
    boundary = boundary.parent!;
  }
  final layer = boundary.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    final image = await layer.toImage(boundary.paintBounds);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    _out.createSync(recursive: true);
    File('${_out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// Deja correr animaciones y temporizadores, en saltos de 100 ms.
Future<void> _wait(WidgetTester tester, [int milliseconds = 1500]) async {
  for (var elapsed = 0; elapsed < milliseconds; elapsed += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('capturas', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (_out.existsSync()) _out.deleteSync(recursive: true);

    await tester.pumpWidget(DeckApp(browser: Browser.current));
    // Las imágenes se decodifican de verdad, fuera del tiempo falso del test.
    final context = tester.element(find.byType(DeckShell));
    await tester.runAsync(() async {
      for (final logo in [
        'assets/brand/flutter_lockup_white.png',
        'assets/brand/flutter_lockup.png',
        'assets/brand/flutter_mark.png',
        'assets/demo/ecoeats_icon.png',
        'assets/demo/ecoeats_splash.png',
        'assets/creditos/jorge.png',
        'assets/creditos/baqjug.png',
        'assets/creditos/devjvm.png',
        'assets/creditos/gniem.png',
        'assets/creditos/caribedev.png',
        'assets/creditos/ieee.png',
        'assets/creditos/uac.png',
      ]) {
        await precacheImage(AssetImage(logo), context);
      }
    });

    // Público de ensayo, para que las votaciones tengan barras.
    await _key(tester, LogicalKeyboardKey.keyS);

    final slides = buildDeck();
    for (final (index, slide) in slides.indexed) {
      final number = (index + 1).toString().padLeft(2, '0');
      for (var step = 0; step < slide.steps; step++) {
        if (step > 0) await _key(tester, LogicalKeyboardKey.arrowRight);
        final last = step == slide.steps - 1;
        if (!last && !_everyStep.contains(slide.id)) {
          await _wait(tester, 300);
          continue;
        }
        await _wait(tester, _longer[slide.id] ?? 3200);
        if (_realWait[slide.id] case final milliseconds?) {
          await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: milliseconds)));
          await _wait(tester, 3200);
        }
        await _shot(tester, last && !_everyStep.contains(slide.id)
            ? '$number-${slide.id}'
            : '$number-${slide.id}-paso-${step + 1}');
      }
      if (slide.id == 'creditos') {
        // El rollo sigue subiendo: el elenco, los organizadores y la escena
        // post-créditos.
        for (final (index, wait) in [12000, 12000, 12000, 16000].indexed) {
          await _wait(tester, wait);
          await _shot(tester, '$number-${slide.id}-${index + 2}');
        }
        await _wait(tester, 8000);
        await _shot(tester, '$number-${slide.id}-post');
        continue;
      }
      if (index == 0) {
        await _key(tester, LogicalKeyboardKey.keyQ);
        await _wait(tester, 600);
        await _shot(tester, '$number-qr-gigante');
        await _key(tester, LogicalKeyboardKey.keyQ);
      }
      if (index < slides.length - 1) {
        await _key(tester, LogicalKeyboardKey.arrowRight);
        // Entre secciones el barrido dura casi un segundo.
        await _wait(tester, 900);
      }
    }

    // Tema de día, para salas con mucha luz.
    await _key(tester, LogicalKeyboardKey.keyT);
    await _key(tester, LogicalKeyboardKey.home);
    await _wait(tester, 3000);
    await _shot(tester, 'dia-doctor');

    await _key(tester, LogicalKeyboardKey.keyS);
    await tester.pumpWidget(const SizedBox());
    await _wait(tester, 300);
  });

  // Con servidor, el QR va en el encabezado de cada votación y les quita
  // alto: así se ven en la charla.
  testWidgets('votaciones con QR', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final browser = Browser.current..write('charla.servidor', 'https://flutter-baq.onrender.com');
    addTearDown(() => browser.write('charla.servidor', ''));
    const ids = {
      'calentamiento',
      'hecha-con-flutter',
      'si-depende-no',
      'pregunta-incomoda',
      'cual-es-dart',
      'publicar',
    };
    final slides = buildDeck().where((slide) => ids.contains(slide.id)).toList();

    await tester.pumpWidget(DeckApp(browser: browser, slides: slides));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/brand/flutter_mark.png'),
        tester.element(find.byType(DeckShell)),
      );
    });
    await tester.tap(find.text('Presentar sin servidor (mano alzada)'));
    await _wait(tester, 600);
    await _key(tester, LogicalKeyboardKey.keyS);

    for (final (index, slide) in slides.indexed) {
      for (var step = 0; step < slide.steps; step++) {
        if (step > 0) await _key(tester, LogicalKeyboardKey.arrowRight);
        await _wait(tester, 3200);
        await _shot(tester, 'qr-${slide.id}-paso-${step + 1}');
      }
      if (index < slides.length - 1) {
        await _key(tester, LogicalKeyboardKey.arrowRight);
        await _wait(tester, 900);
      }
    }

    await _key(tester, LogicalKeyboardKey.keyS);
    await tester.pumpWidget(const SizedBox());
    await _wait(tester, 300);
  });

  testWidgets('pantalla de entrada del presentador', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final live = LiveController(
      config: LiveConfig(server: Uri.parse('https://flutter-baq.onrender.com')),
    );
    addTearDown(live.dispose);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: deckTheme(DeckColors.night),
        home: Stage(child: PresenterLogin(live: live, browser: Browser.current)),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/brand/flutter_lockup_white.png'),
        tester.element(find.byType(PresenterLogin)),
      );
    });
    await tester.enterText(find.byType(TextField), 'secreto');
    await _wait(tester, 600);
    await _shot(tester, 'login-presentador');
  });
}
