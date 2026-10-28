import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Los colores de la charla en sus dos versiones: noche (por defecto) y
/// día, para salas con mucha luz. El cambio entre ambos se interpola con
/// [lerp], igual que cualquier tema de Flutter.
@immutable
class DeckColors extends ThemeExtension<DeckColors> {
  const DeckColors({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.raised,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.line,
    required this.grid,
    required this.accent,
    required this.accentText,
    required this.deep,
    required this.guide,
    required this.success,
    required this.danger,
  });

  static const night = DeckColors(
    brightness: Brightness.dark,
    canvas: Color(0xFF030A17),
    surface: Color(0xFF071A33),
    raised: Color(0xFF0B2447),
    ink: Color(0xFFEEF4FF),
    muted: Color(0xFF94A8C8),
    faint: Color(0xFF5F7395),
    line: Color(0xFF173055),
    grid: Color(0xFF0E203F),
    accent: FlutterBrand.sky,
    accentText: Color(0xFF5BAAFF),
    deep: FlutterBrand.navy,
    guide: Color(0xFF54C5F8),
    success: FlutterBrand.green,
    danger: FlutterBrand.red,
  );

  static const day = DeckColors(
    brightness: Brightness.light,
    canvas: Color(0xFFF4F7FC),
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFE6EEFA),
    ink: Color(0xFF071833),
    muted: Color(0xFF465A7B),
    faint: Color(0xFF7B8BA7),
    line: Color(0xFFD3DDEB),
    grid: Color(0xFFDDE5F1),
    accent: FlutterBrand.sky,
    accentText: FlutterBrand.blue,
    deep: FlutterBrand.navy,
    guide: Color(0xFF0090D4),
    success: Color(0xFF0A9787),
    danger: Color(0xFFD5433A),
  );

  final Brightness brightness;
  final Color canvas;
  final Color surface;
  final Color raised;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color line;
  final Color grid;

  /// Flutter Sky: rellenos, barras y lo que está activo.
  final Color accent;

  /// El acento cuando es texto: más claro de noche, más oscuro de día, para
  /// que se lea en el proyector.
  final Color accentText;
  final Color deep;

  /// El cian de las guías de depuración del Inspector.
  final Color guide;
  final Color success;
  final Color danger;

  bool get isNight => brightness == Brightness.dark;

  @override
  DeckColors copyWith({Color? canvas, Color? ink}) => DeckColors(
    brightness: brightness,
    canvas: canvas ?? this.canvas,
    surface: surface,
    raised: raised,
    ink: ink ?? this.ink,
    muted: muted,
    faint: faint,
    line: line,
    grid: grid,
    accent: accent,
    accentText: accentText,
    deep: deep,
    guide: guide,
    success: success,
    danger: danger,
  );

  @override
  DeckColors lerp(DeckColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return DeckColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      raised: mix(raised, other.raised),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      faint: mix(faint, other.faint),
      line: mix(line, other.line),
      grid: mix(grid, other.grid),
      accent: mix(accent, other.accent),
      accentText: mix(accentText, other.accentText),
      deep: mix(deep, other.deep),
      guide: mix(guide, other.guide),
      success: mix(success, other.success),
      danger: mix(danger, other.danger),
    );
  }
}

/// El código siempre va en un editor oscuro, en los dos temas: así se ve
/// igual en cualquier proyector.
abstract final class CodeColors {
  static const background = Color(0xFF06142A);
  static const header = Color(0xFF0A1C38);
  static const border = Color(0xFF17305A);
  static const plain = Color(0xFFE4ECFB);
  static const keyword = Color(0xFF6FB7FF);
  static const type = Color(0xFF54C5F8);
  static const string = Color(0xFF8DE2CB);
  static const number = Color(0xFFFFC98A);
  static const comment = Color(0xFF63789B);
  static const annotation = Color(0xFFC4B2FF);
  static const function = Color(0xFFB5CCFF);
  static const punctuation = Color(0xFF8297BA);
  static const lineNumber = Color(0xFF34496D);
  static const focus = Color(0xFF0E2C57);
}

ThemeData deckTheme(DeckColors colors) {
  final base = ThemeData(
    brightness: colors.brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FlutterBrand.sky,
      brightness: colors.brightness,
    ),
    fontFamily: DeckFonts.sans,
    scaffoldBackgroundColor: colors.canvas,
  );
  return base.copyWith(extensions: [colors]);
}

extension DeckColorsContext on BuildContext {
  DeckColors get colors =>
      Theme.of(this).extension<DeckColors>() ?? DeckColors.night;
}
