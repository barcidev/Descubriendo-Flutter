import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/flutter_lockup.dart';
import 'join_card.dart';
import 'live_controller.dart';

/// La puerta del modo presentador: sin el token, la charla no maneja los
/// celulares. El token se escribe aquí (oculto) y viaja dentro del
/// WebSocket; el servidor devuelve una sesión que vence sola y queda
/// guardada en este navegador.
class PresenterLogin extends StatefulWidget {
  const PresenterLogin({required this.live, super.key});

  final LiveController live;

  @override
  State<PresenterLogin> createState() => _PresenterLoginState();
}

class _PresenterLoginState extends State<PresenterLogin> {
  final _token = TextEditingController();
  final _focus = FocusNode();
  bool _visible = false;

  @override
  void dispose() {
    _token.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    widget.live.login(_token.text);
    _token.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = widget.live;
    final checking = live.access == PresenterAccess.checking;
    final status = switch ((live.socketOpen, checking, live.loginError)) {
      (_, _, final error?) => (error, colors.danger),
      (false, _, _) => ('Despertando el servidor… (en el plan gratis tarda hasta un minuto)', colors.muted),
      (true, true, _) => ('Verificando…', colors.accentText),
      _ => ('Conectado a ${displayUrl(live.joinUrl)}', colors.success),
    };
    return ColoredBox(
      color: colors.canvas,
      child: Center(
        child: SizedBox(
          width: 1040,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FlutterLockup(height: 44),
                const SizedBox(height: 56),
                Text('Modo presentador', style: DeckType.display.copyWith(color: colors.ink)),
                const SizedBox(height: 12),
                Text(
                  '${Config.title}: solo quien tiene el token maneja los celulares.',
                  style: DeckType.headline.copyWith(fontSize: 34, color: colors.muted),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 26, 32, 30),
                  decoration: BoxDecoration(
                    color: CodeColors.background,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: CodeColors.border, width: Space.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: r'$ ', style: TextStyle(color: FlutterBrand.sky)),
                            const TextSpan(text: 'sudo flutter run --presentador'),
                          ],
                        ),
                        style: DeckType.mono.copyWith(fontSize: 28, color: CodeColors.plain),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            '[sudo] token del presentador: ',
                            style: DeckType.mono.copyWith(fontSize: 28, color: CodeColors.comment),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _token,
                              focusNode: _focus,
                              autofocus: true,
                              obscureText: !_visible,
                              enabled: live.access != PresenterAccess.checking || !live.socketOpen,
                              autofillHints: const [AutofillHints.password],
                              cursorColor: FlutterBrand.sky,
                              style: DeckType.mono.copyWith(fontSize: 28, color: CodeColors.plain),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                          ExcludeFocus(
                            child: IconButton(
                              tooltip: _visible ? 'Ocultar' : 'Mostrar',
                              onPressed: () => setState(() => _visible = !_visible),
                              icon: Icon(
                                _visible ? Icons.visibility_off : Icons.visibility,
                                color: CodeColors.punctuation,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: Motion.quick,
                  child: Text(
                    status.$1,
                    key: ValueKey(status.$1),
                    style: DeckType.small.copyWith(color: status.$2),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    ExcludeFocus(
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
                          textStyle: DeckType.small.copyWith(fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ExcludeFocus(
                      child: TextButton(
                        onPressed: live.skipLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.muted,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                          textStyle: DeckType.small,
                        ),
                        child: const Text('Presentar sin servidor (mano alzada)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
