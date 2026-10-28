import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

/// Las excusas de siempre. El público suma las suyas durante la charla.
const excuses = [
  'Funciona en mi máquina.',
  'Es un tema de caché.',
  'Debe ser el DNS.',
  'Eso no lo toqué yo.',
  'En staging no pasaba.',
  'No es un bug, es un feature.',
  'Ayer funcionaba.',
  'Fue el último merge.',
  'Seguro es el wifi del cliente.',
  'Hice flutter clean y quedó peor.',
  'El compilador amaneció de mal genio.',
  'No hay tests para eso, pero confía.',
];

const excuseAuthor = '— Todo dev, alguna vez';

/// Un tema de Material con la fuente de la charla, para que las demos se
/// vean como una app real sin depender de fuentes de internet.
ThemeData demoTheme(Brightness brightness, {Color seed = FlutterBrand.sky}) =>
    ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      fontFamily: DeckFonts.sans,
    );

/// La tarjeta del Excusómetro: el ejemplo que acompaña toda la charla.
class ExcuseCard extends StatelessWidget {
  const ExcuseCard({
    required this.excuse,
    this.author = excuseAuthor,
    this.header = true,
    this.onAnother,
    super.key,
  });

  final String excuse;
  final String author;

  /// Muestra la fila del ícono y el nombre de la app.
  final bool header;

  /// Si no es nulo, aparece el botón «Otra excusa».
  final VoidCallback? onAnother;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header)
              Row(
                children: [
                  Icon(Icons.bug_report, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Excusómetro', style: text.labelLarge),
                ],
              ),
            if (header) const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: Motion.base,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, ?current],
              ),
              child: Text(
                excuse,
                key: ValueKey(excuse),
                style: text.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            Text(author, style: text.bodyMedium),
            if (onAnother != null) ...[
              const SizedBox(height: 20),
              // Sin foco: el espacio y las flechas siempre son de la charla.
              ExcludeFocus(
                child: FilledButton(
                  onPressed: onAnother,
                  child: const Text('Otra excusa'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
