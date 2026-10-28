import 'package:flutter/widgets.dart';

import '../theme/deck_theme.dart';
import '../theme/tokens.dart';

/// El logo oficial de Flutter, sin alterar: blanco sobre fondos oscuros y a
/// color sobre claros, como pide la guía de marca.
class FlutterLockup extends StatelessWidget {
  const FlutterLockup({this.height = 56, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    final night = context.colors.isNight;
    return Image.asset(
      night
          ? 'assets/brand/flutter_lockup_white.png'
          : 'assets/brand/flutter_lockup.png',
      height: height,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Flutter',
    );
  }
}

/// La nota de marca que pide flutter.dev/brand cerca del primer uso del logo.
class TrademarkNote extends StatelessWidget {
  const TrademarkNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Flutter y el logo relacionado son marcas comerciales de Google LLC. '
      'Esta charla no está respaldada por Google LLC ni afiliada a ella.',
      style: DeckType.caption.copyWith(
        fontSize: 16,
        color: context.colors.faint,
      ),
    );
  }
}
