import 'package:flutter/widgets.dart';

/// Colores oficiales de la guía de marca de Flutter (flutter.dev/brand).
abstract final class FlutterBrand {
  static const navy = Color(0xFF042B59);
  static const blue = Color(0xFF0553B1);
  static const sky = Color(0xFF027DFD);

  /// Acentos primarios de la misma guía.
  static const red = Color(0xFFF25D50);
  static const yellow = Color(0xFFFFF275);
  static const purple = Color(0xFF6200EE);
  static const green = Color(0xFF1CDAC5);
}

/// El lienzo de la charla: todo se diseña a 1920 × 1080 y se escala al
/// proyector que toque.
abstract final class Canvas16x9 {
  static const width = 1920.0;
  static const height = 1080.0;
  static const size = Size(width, height);
}

abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 32;
  static const double xl = 48;
  static const double xxl = 72;

  /// Margen lateral de cada diapositiva.
  static const double pageX = 120;
  static const double pageTop = 96;

  /// Alto de la barra de estado del pie.
  static const double statusBar = 46;
  static const double pageBottom = statusBar + 64;

  static const double hairline = 1.5;
}

abstract final class Radii {
  static const double sm = 10;
  static const double md = 18;
  static const double lg = 28;
}

abstract final class Motion {
  static const quick = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 360);
  static const slow = Duration(milliseconds: 620);

  /// El barrido diagonal entre secciones.
  static const wipe = Duration(milliseconds: 820);

  static const emphasized = Cubic(0.2, 0, 0, 1);
  static const out = Curves.easeOutCubic;
  static const inOut = Curves.easeInOutCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

abstract final class DeckFonts {
  static const sans = 'GoogleSansFlex';
  static const mono = 'GoogleSansCode';
}

/// La escala tipográfica. Los estilos no llevan color: lo pone el tema.
///
/// Google Sans Flex es variable (opsz, wdth, wght, ROND, slnt), así que cada
/// estilo fija sus ejes en vez de confiar en [FontWeight].
abstract final class DeckType {
  static List<FontVariation> _sans(double weight, double opsz) => [
    FontVariation('wght', weight),
    FontVariation('opsz', opsz),
  ];

  static final hero = TextStyle(
    fontFamily: DeckFonts.sans,
    fontSize: 132,
    height: 1.0,
    letterSpacing: -4.2,
    fontWeight: FontWeight.w600,
    fontVariations: _sans(620, 144),
  );

  static final display = TextStyle(
    fontFamily: DeckFonts.sans,
    fontSize: 96,
    height: 1.04,
    letterSpacing: -2.6,
    fontWeight: FontWeight.w600,
    fontVariations: _sans(600, 120),
  );

  static final title = TextStyle(
    fontFamily: DeckFonts.sans,
    fontSize: 68,
    height: 1.08,
    letterSpacing: -1.6,
    fontWeight: FontWeight.w600,
    fontVariations: _sans(590, 80),
  );

  static final headline = TextStyle(
    fontFamily: DeckFonts.sans,
    fontSize: 44,
    height: 1.18,
    letterSpacing: -0.7,
    fontWeight: FontWeight.w500,
    fontVariations: _sans(480, 48),
  );

  static final body = TextStyle(
    fontFamily: DeckFonts.sans,
    fontSize: 34,
    height: 1.38,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w400,
    fontVariations: _sans(420, 28),
  );

  static final bodyStrong = body.copyWith(
    fontWeight: FontWeight.w600,
    fontVariations: _sans(600, 28),
  );

  static final small = TextStyle(
    fontFamily: DeckFonts.sans,
    fontSize: 26,
    height: 1.35,
    fontWeight: FontWeight.w400,
    fontVariations: _sans(430, 22),
  );

  static final caption = TextStyle(
    fontFamily: DeckFonts.sans,
    fontSize: 20,
    height: 1.35,
    fontWeight: FontWeight.w400,
    fontVariations: _sans(440, 18),
  );

  static const _monoAxes = [FontVariation('wght', 430)];

  static const code = TextStyle(
    fontFamily: DeckFonts.mono,
    fontSize: 28,
    height: 1.5,
    fontWeight: FontWeight.w400,
    fontVariations: _monoAxes,
    fontFeatures: [FontFeature.disable('calt')],
  );

  static const mono = TextStyle(
    fontFamily: DeckFonts.mono,
    fontSize: 24,
    height: 1.4,
    fontWeight: FontWeight.w400,
    fontVariations: _monoAxes,
  );

  static const monoSmall = TextStyle(
    fontFamily: DeckFonts.mono,
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const monoLabel = TextStyle(
    fontFamily: DeckFonts.mono,
    fontSize: 20,
    height: 1.2,
    letterSpacing: 0.4,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  static const tabular = [FontFeature.tabularFigures()];
}
