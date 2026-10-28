import 'package:material_ui/material_ui.dart';

import '../engine/browser.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';

/// Entra o sale de pantalla completa (lo mismo que la tecla F). El ícono
/// sigue el estado real: si se sale con Esc, también cambia.
class FullscreenButton extends StatelessWidget {
  const FullscreenButton({
    required this.browser,
    this.label = false,
    this.size = 20,
    super.key,
  });

  final Browser browser;

  /// Muestra el texto al lado del ícono.
  final bool label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder(
      valueListenable: browser.fullscreen,
      builder: (context, full, _) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: browser.toggleFullscreen,
          child: Semantics(
            button: true,
            label: full ? 'Salir de pantalla completa' : 'Pantalla completa',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  full ? Icons.fullscreen_exit : Icons.fullscreen,
                  size: size,
                  color: label ? colors.muted : colors.faint,
                ),
                if (label) ...[
                  const SizedBox(width: 10),
                  Text(
                    full ? 'Salir de pantalla completa (F)' : 'Pantalla completa (F)',
                    style: DeckType.small.copyWith(color: colors.muted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
