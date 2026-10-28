import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:path_parsing/path_parsing.dart';

import '../theme/deck_theme.dart';
import '../theme/tokens.dart';

/// Las apps del quiz, cada una con el ícono que la gente tiene en el
/// celular: el logo oficial sobre el fondo de su ícono de app.
///
/// Los trazos vienen de Simple Icons 16.30.0 (CC0, simpleicons.org), que
/// copia cada logo de la página de prensa de su marca. Los logos siguen
/// siendo marcas de sus dueños: aquí solo identifican cada app.
enum AppBrand {
  googlePay(
    'Google Pay',
    // Solo la G: el resto («Pay») va aparte para pintarla de colores.
    d: 'M3.963 7.235A3.963 3.963 0 00.422 9.419a3.963 3.963 0 000 3.559 3.963 3.963 0 003.541 2.184c1.07 0 1.97-.352 2.627-.957.748-.69 1.18-1.71 1.18-2.916a4.722 4.722 0 00-.07-.806H3.964v1.526h2.14a1.835 1.835 0 01-.79 1.205c-.356.241-.814.379-1.35.379-1.034 0-1.911-.697-2.225-1.636a2.375 2.375 0 010-1.517c.314-.94 1.191-1.636 2.225-1.636a2.152 2.152 0 011.52.594l1.132-1.13a3.808 3.808 0 00-2.652-1.033z',
    background: Color(0xFFFFFFFF),
    glyph: Color(0xFF5F6368),
    scale: 0.8,
  ),
  nubank(
    'Nubank',
    d: 'M7.2795 5.4336c-1.1815 0-2.1846.4628-2.9432 1.252h-.002c-.0541-.0022-.1074-.002-.162-.002-1.5436 0-2.9925.8835-3.699 2.2559-.3088.5996-.4234 1.2442-.459 1.9003-.0321.589 0 1.1863 0 1.7696v5.6523H3.184s.0022-2.784 0-5.1777c-.0014-1.6112-.0118-3.0471 0-3.3418.056-1.3937.4372-2.3053 1.1484-3.0508 2.3585.0018 3.8852 1.6091 3.9705 4.168.0196.5874.0254 3.7304.0254 3.7304v3.672h3.1678v-4.965c0-1.5007.0127-2.8006-.0918-3.6952-.292-2.5-1.821-4.168-4.1248-4.168zm8.3903.3008l-3.166.0039v4.9648c0 1.5009-.0127 2.8007.0919 3.6953.2921 2.5001 1.821 4.168 4.1248 4.168 1.1815 0 2.1846-.4628 2.9432-1.252.0003-.0003.0016.0004.002 0 .0542.0023.1093.002.164.002 1.5435 0 2.9905-.8835 3.6971-2.2558.3088-.5997.4233-1.2442.459-1.9004.032-.5889 0-1.1862 0-1.7695V5.7383H20.816s-.0022 2.784 0 5.1777c.0015 1.6113.0119 3.047 0 3.3418-.056 1.3935-.4372 2.3053-1.1483 3.0508-2.3586-.0018-3.8853-1.6091-3.9706-4.168-.0196-.5874-.0273-2.0437-.0273-3.7324Z',
    background: Color(0xFF820AD1),
    scale: 0.6,
  ),
  whatsapp(
    'WhatsApp',
    d: 'M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z',
    background: Color(0xFF25D366),
    scale: 0.62,
  ),
  bmw(
    'BMW',
    d: 'M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm0 .78C18.196.78 23.219 5.803 23.219 12c0 6.196-5.022 11.219-11.219 11.219C5.803 23.219.781 18.196.781 12S5.804.78 12 .78zm-.678.63c-.33.014-.66.042-.992.078l-.107 2.944a9.95 9.95 0 0 1 .71-.094l.07-1.988-.013-.137.043.13.664 1.489h.606l.664-1.488.04-.131-.01.137.07 1.988c.232.022.473.054.71.094l-.109-2.944a14.746 14.746 0 0 0-.992-.078l-.653 1.625-.023.12-.023-.12-.655-1.625zm6.696 1.824l-1.543 2.428c.195.15.452.371.617.522l1.453-.754.092-.069-.069.094-.752 1.453c.163.175.398.458.53.63l2.43-1.544a16.135 16.135 0 0 0-.46-.568L18.777 6.44l-.105.092.078-.115.68-1.356-.48-.48-1.356.68-.115.078.091-.106 1.018-1.539c-.18-.152-.351-.291-.57-.46zM5.5 3.785c-.36.037-.638.283-1.393 1.125a18.97 18.97 0 0 0-.757.914l2.074 1.967c.687-.76.966-1.042 1.508-1.613.383-.405.6-.87.216-1.317-.208-.242-.558-.295-.85-.175l-.028.01.01-.026a.7.7 0 0 0-.243-.734.724.724 0 0 0-.537-.15zm.006.615c.136-.037.277.06.308.2.032.14-.056.272-.154.382-.22.25-1.031 1.098-1.031 1.098l-.402-.383c.417-.51.861-.974 1.062-1.158a.55.55 0 0 1 .217-.139zM12 4.883a7.114 7.114 0 0 0-7.08 6.388v.002a7.122 7.122 0 0 0 8.516 7.697 7.112 7.112 0 0 0 5.68-6.97A7.122 7.122 0 0 0 12 4.885v-.002zm-5.537.242c.047 0 .096.013.14.043.088.059.128.16.106.26-.026.119-.125.231-.205.318l-1.045 1.12-.42-.4s.787-.832 1.045-1.099c.102-.106.168-.17.238-.205a.331.331 0 0 1 .14-.037zM12 5.818A6.175 6.175 0 0 1 18.182 12H12v6.182A6.175 6.175 0 0 1 5.818 12H12V5.818Z',
    background: Color(0xFF000000),
    scale: 0.76,
  ),
  uber(
    'Uber',
    d: 'M0 7.97v4.958c0 1.867 1.302 3.101 3 3.101.826 0 1.562-.316 2.094-.87v.736H6.27V7.97H5.082v4.888c0 1.257-.85 2.106-1.947 2.106-1.11 0-1.946-.827-1.946-2.106V7.971H0zm7.44 0v7.925h1.13v-.725c.521.532 1.257.86 2.06.86a3.006 3.006 0 0 0 3.034-3.01 3.01 3.01 0 0 0-3.033-3.024 2.86 2.86 0 0 0-2.049.861V7.971H7.439zm9.869 2.038c-1.687 0-2.965 1.37-2.965 3 0 1.72 1.334 3.01 3.066 3.01 1.053 0 1.913-.463 2.49-1.233l-.826-.611c-.43.577-.996.847-1.664.847-.973 0-1.753-.7-1.912-1.64h4.697v-.373c0-1.72-1.222-3-2.886-3zm6.295.068c-.634 0-1.098.294-1.381.758v-.713h-1.131v5.774h1.142V12.61c0-.894.544-1.47 1.291-1.47H24v-1.065h-.396zm-6.319.928c.85 0 1.564.588 1.756 1.47H15.52c.203-.882.916-1.47 1.765-1.47zm-6.732.012c1.086 0 1.98.883 1.98 2.004a1.993 1.993 0 0 1-1.98 2.001A1.989 1.989 0 0 1 8.56 13.02a1.99 1.99 0 0 1 1.992-2.004z',
    background: Color(0xFF000000),
    scale: 0.7,
  ),
  notebookLm(
    'NotebookLM',
    d: 'M11.999 3.201C5.372 3.201 0 8.528 0 15.101V20.8h2.212v-.568c0-2.666 2.178-4.827 4.866-4.827 2.688 0 4.866 2.16 4.866 4.827v.568h2.212v-.568c0-3.877-3.17-7.019-7.078-7.019A7.075 7.075 0 0 0 2.992 14.5a7.355 7.355 0 0 1 6.568-4.016c4.057 0 7.347 3.264 7.347 7.287V20.8h2.212V17.77c0-5.235-4.28-9.481-9.56-9.481a9.563 9.563 0 0 0-6.217 2.28A9.795 9.795 0 0 1 12 5.393c5.406 0 9.788 4.346 9.788 9.707V20.8H24V15.1c-.001-6.573-5.373-11.9-12.001-11.9Z',
    background: Color(0xFF000000),
    scale: 0.62,
  ),
  instagram(
    'Instagram',
    d: 'M7.0301.084c-1.2768.0602-2.1487.264-2.911.5634-.7888.3075-1.4575.72-2.1228 1.3877-.6652.6677-1.075 1.3368-1.3802 2.127-.2954.7638-.4956 1.6365-.552 2.914-.0564 1.2775-.0689 1.6882-.0626 4.947.0062 3.2586.0206 3.6671.0825 4.9473.061 1.2765.264 2.1482.5635 2.9107.308.7889.72 1.4573 1.388 2.1228.6679.6655 1.3365 1.0743 2.1285 1.38.7632.295 1.6361.4961 2.9134.552 1.2773.056 1.6884.069 4.9462.0627 3.2578-.0062 3.668-.0207 4.9478-.0814 1.28-.0607 2.147-.2652 2.9098-.5633.7889-.3086 1.4578-.72 2.1228-1.3881.665-.6682 1.0745-1.3378 1.3795-2.1284.2957-.7632.4966-1.636.552-2.9124.056-1.2809.0692-1.6898.063-4.948-.0063-3.2583-.021-3.6668-.0817-4.9465-.0607-1.2797-.264-2.1487-.5633-2.9117-.3084-.7889-.72-1.4568-1.3876-2.1228C21.2982 1.33 20.628.9208 19.8378.6165 19.074.321 18.2017.1197 16.9244.0645 15.6471.0093 15.236-.005 11.977.0014 8.718.0076 8.31.0215 7.0301.0839m.1402 21.6932c-1.17-.0509-1.8053-.2453-2.2287-.408-.5606-.216-.96-.4771-1.3819-.895-.422-.4178-.6811-.8186-.9-1.378-.1644-.4234-.3624-1.058-.4171-2.228-.0595-1.2645-.072-1.6442-.079-4.848-.007-3.2037.0053-3.583.0607-4.848.05-1.169.2456-1.805.408-2.2282.216-.5613.4762-.96.895-1.3816.4188-.4217.8184-.6814 1.3783-.9003.423-.1651 1.0575-.3614 2.227-.4171 1.2655-.06 1.6447-.072 4.848-.079 3.2033-.007 3.5835.005 4.8495.0608 1.169.0508 1.8053.2445 2.228.408.5608.216.96.4754 1.3816.895.4217.4194.6816.8176.9005 1.3787.1653.4217.3617 1.056.4169 2.2263.0602 1.2655.0739 1.645.0796 4.848.0058 3.203-.0055 3.5834-.061 4.848-.051 1.17-.245 1.8055-.408 2.2294-.216.5604-.4763.96-.8954 1.3814-.419.4215-.8181.6811-1.3783.9-.4224.1649-1.0577.3617-2.2262.4174-1.2656.0595-1.6448.072-4.8493.079-3.2045.007-3.5825-.006-4.848-.0608M16.953 5.5864A1.44 1.44 0 1 0 18.39 4.144a1.44 1.44 0 0 0-1.437 1.4424M5.8385 12.012c.0067 3.4032 2.7706 6.1557 6.173 6.1493 3.4026-.0065 6.157-2.7701 6.1506-6.1733-.0065-3.4032-2.771-6.1565-6.174-6.1498-3.403.0067-6.156 2.771-6.1496 6.1738M8 12.0077a4 4 0 1 1 4.008 3.9921A3.9996 3.9996 0 0 1 8 12.0077',
    // El degradado del ícono de Instagram, que nace abajo a la izquierda.
    gradient: RadialGradient(
      center: Alignment(-0.4, 1.14),
      radius: 1.3,
      colors: [
        Color(0xFFFDF497),
        Color(0xFFFDF497),
        Color(0xFFFD5949),
        Color(0xFFD6249F),
        Color(0xFF285AEB),
      ],
      stops: [0, 0.05, 0.45, 0.6, 0.9],
    ),
    scale: 0.6,
  ),

  /// El ícono que trae toda app recién salida de `flutter create`.
  flutter('Flutter', background: Color(0xFFFFFFFF), scale: 0.56);

  const AppBrand(
    this.name, {
    this.d,
    this.background,
    this.gradient,
    this.glyph = const Color(0xFFFFFFFF),
    required this.scale,
  });

  final String name;

  /// El logo, como el atributo `d` de un `<path>` SVG de 24×24.
  final String? d;
  final Color? background;
  final Gradient? gradient;
  final Color glyph;

  /// Qué parte del ícono ocupa el logo, en su lado más largo.
  final double scale;
}

/// El ícono de [brand], redondeado como en la pantalla de un celular.
class AppIcon extends StatelessWidget {
  const AppIcon(this.brand, {this.size = 64, super.key});

  final AppBrand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.225);
    return Semantics(
      label: brand.name,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: brand.background,
          gradient: brand.gradient,
          borderRadius: radius,
          // Los íconos negros no se pierden en una tarjeta oscura, ni los
          // blancos en el tema claro.
          border: Border.all(
            color: context.colors.ink.withValues(alpha: 0.14),
            width: Space.hairline,
          ),
        ),
        child: brand == AppBrand.flutter
            ? Padding(
                padding: EdgeInsets.all(size * (1 - brand.scale) / 2),
                child: Image.asset(
                  'assets/brand/flutter_mark.png',
                  filterQuality: FilterQuality.medium,
                ),
              )
            : CustomPaint(painter: _LogoPainter(brand)),
      ),
    );
  }
}

final _paths = <AppBrand, Path>{};

Path _pathOf(AppBrand brand) =>
    _paths.putIfAbsent(brand, () => _parse(brand.d!));

Path _parse(String d) {
  final proxy = _PathProxy();
  writeSvgPathDataToPath(d, proxy);
  return proxy.path;
}

class _PathProxy extends PathProxy {
  final path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

/// «Pay», del mismo logo de Google Pay. Empieza donde Simple Icons pasa de
/// la G a la P, ya en coordenadas absolutas.
final _pay = _parse(
  'M10.464 7.785v6.9h.886V11.89h1.465c.603 0 1.11-.196 1.522-.588a1.911 1.911 0 00.635-1.464 1.92 1.92 0 00-.635-1.456 2.125 2.125 0 00-1.522-.598zm2.427.85a1.156 1.156 0 01.823.365 1.176 1.176 0 010 1.686 1.171 1.171 0 01-.877.357H11.35V8.635h1.487a1.156 1.156 0 01.054 0zm4.124 1.175c-.842 0-1.477.308-1.907.925l.781.491c.288-.417.68-.626 1.175-.626a1.255 1.255 0 01.856.323 1.009 1.009 0 01.366.785v.202c-.34-.193-.774-.289-1.3-.289-.617 0-1.11.145-1.479.434-.37.288-.554.677-.554 1.165a1.476 1.476 0 00.525 1.156c.35.308.785.463 1.305.463.61 0 1.098-.27 1.465-.81h.038v.655h.848v-2.909c0-.61-.19-1.09-.568-1.44-.38-.35-.896-.525-1.551-.525zm2.263.154l1.946 4.422-1.098 2.38h.915L24 9.963h-.965l-1.368 3.391h-.02l-1.406-3.39zm-2.146 2.368c.494 0 .88.11 1.156.33 0 .372-.147.696-.44.973a1.413 1.413 0 01-.997.414 1.081 1.081 0 01-.69-.232.708.708 0 01-.293-.578c0-.257.12-.47.363-.647.24-.173.54-.26.9-.26Z',
);

class _LogoPainter extends CustomPainter {
  const _LogoPainter(this.brand);

  final AppBrand brand;

  @override
  void paint(Canvas canvas, Size size) {
    final logo = _pathOf(brand);
    final bounds = brand == AppBrand.googlePay
        ? logo.getBounds().expandToInclude(_pay.getBounds())
        : logo.getBounds();
    // El logo se centra y crece hasta [AppBrand.scale] del ícono.
    final fit = size.shortestSide * brand.scale / bounds.longestSide;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(fit)
      ..translate(-bounds.center.dx, -bounds.center.dy);
    switch (brand) {
      case AppBrand.googlePay:
        _paintGoogleG(canvas, logo);
        canvas.drawPath(_pay, Paint()..color = brand.glyph);
      case AppBrand.bmw:
        // Los cuartos azules son huecos del logo: el azul va debajo.
        canvas
          ..drawCircle(
            const Offset(12, 12),
            6.6,
            Paint()..color = const Color(0xFF0066B1),
          )
          ..drawPath(logo, Paint()..color = brand.glyph);
      default:
        canvas.drawPath(logo, Paint()..color = brand.glyph);
    }
    canvas.restore();
  }

  /// La G de cuatro colores: cada color es una tajada alrededor del centro,
  /// recortada con la forma de la G, y la barra va en azul.
  void _paintGoogleG(Canvas canvas, Path g) {
    const center = Offset(3.963, 11.2);
    const blue = Color(0xFF4285F4);
    final ring = Rect.fromCircle(center: center, radius: 5);
    double rad(double degrees) => degrees * math.pi / 180;
    canvas
      ..save()
      ..clipPath(g);
    for (final (from, to, color) in const [
      (-10.0, 45.0, blue),
      (45.0, 140.0, Color(0xFF34A853)),
      (140.0, 220.0, Color(0xFFFBBC04)),
      (220.0, 350.0, Color(0xFFEA4335)),
    ]) {
      canvas.drawArc(
        ring,
        rad(from),
        rad(to - from),
        true,
        Paint()..color = color,
      );
    }
    canvas
      ..drawRect(
        const Rect.fromLTRB(3.9, 10.45, 8, 12.05),
        Paint()..color = blue,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => oldDelegate.brand != brand;
}
