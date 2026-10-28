import 'package:material_ui/material_ui.dart';

import '../engine/deck_scope.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/qr_code.dart';

/// El QR para entrar desde el celular, con la dirección escrita para quien
/// no pueda escanear y cuántas personas ya están adentro.
class JoinCard extends StatelessWidget {
  const JoinCard({this.qrSize = 300, this.compact = false, super.key});

  final double qrSize;

  /// La versión pequeña, para la esquina de una votación.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) {
        final url = live.joinUrl;
        if (url.isEmpty) return _NoServer(compact: compact);
        final count = live.connected;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrCode(data: url, size: qrSize),
            SizedBox(width: compact ? 22 : 44),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  compact ? 'Vota desde el celular' : 'Escanea y entra',
                  style: (compact ? DeckType.small : DeckType.headline)
                      .copyWith(color: colors.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  displayUrl(url),
                  style: (compact ? DeckType.monoSmall : DeckType.mono)
                      .copyWith(color: colors.accentText),
                ),
                const SizedBox(height: 10),
                Text(
                  count == 1
                      ? '1 persona conectada'
                      : '$count personas conectadas',
                  style: DeckType.monoSmall.copyWith(
                    color: colors.muted,
                    fontFeatures: DeckType.tabular,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// La dirección como se lee en voz alta: sin esquema y en minúsculas.
String displayUrl(String url) =>
    url.replaceFirst(RegExp('^https?://'), '').replaceFirst(RegExp(r'/$'), '');

class _NoServer extends StatelessWidget {
  const _NoServer({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 28),
      decoration: BoxDecoration(
        border: Border.all(color: colors.line, width: Space.hairline),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pan_tool, color: colors.muted, size: compact ? 28 : 40),
          const SizedBox(width: 16),
          Text(
            'Mano alzada',
            style: (compact ? DeckType.small : DeckType.headline).copyWith(
              color: colors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// El QR gigante (tecla Q): ocupa casi todo el alto, para que lo lean
/// hasta en la última fila.
class QrOverlay extends StatelessWidget {
  const QrOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    return ColoredBox(
      color: colors.canvas,
      child: ListenableBuilder(
        listenable: live,
        builder: (context, _) {
          final url = live.joinUrl;
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (url.isEmpty)
                  const _NoServer(compact: false)
                else
                  QrCode(data: url, size: 860),
                const SizedBox(width: 72),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abre la cámara\ny apunta aquí',
                        style: DeckType.display.copyWith(color: colors.ink),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        displayUrl(url),
                        style: DeckType.mono.copyWith(
                          fontSize: 34,
                          color: colors.accentText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Un solo escaneo sirve para toda la charla.',
                        style: DeckType.body.copyWith(color: colors.muted),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        '${live.connected} conectados',
                        style: DeckType.mono.copyWith(
                          color: colors.success,
                          fontFeatures: DeckType.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
