import 'package:material_ui/material_ui.dart';

import '../engine/slide.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/blocks.dart';
import '../ui/reveal.dart';
import '../ui/slide_scaffold.dart';
import '../ui/terminal.dart';
import 'sections.dart';

final devicesSlides = [
  Slide(
    id: 'devices',
    section: devicesSection,
    title: 'flutter devices',
    steps: 2,
    builder: (context, step) => _Devices(step: step),
  ),
  Slide(
    id: 'donde-vive',
    section: devicesSection,
    title: 'Dónde vive Flutter',
    builder: (context, step) => const _WhereItLives(),
  ),
];

// El formato real de `flutter devices`, con lo que hay en un Mac de trabajo.
const _devicesLines = [
  TermLine.command('flutter devices'),
  TermLine('Found 4 connected devices:', pause: Duration(milliseconds: 700)),
  TermLine(
    '  iPhone 17 Pro (mobile) • 9A3F…C2 • ios            • iOS 26.2 (simulator)',
    tone: TermTone.accent,
  ),
  TermLine(
    '  Pixel 9 (mobile)       • emulator-5554 • android-arm64 • Android 16 (API 36)',
    tone: TermTone.accent,
  ),
  TermLine(
    '  macOS (desktop)        • macos   • darwin-arm64   • macOS 26.1',
    tone: TermTone.accent,
  ),
  TermLine(
    '  Chrome (web)           • chrome  • web-javascript • Google Chrome 156',
    tone: TermTone.accent,
  ),
];

class _Devices extends StatelessWidget {
  const _Devices({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'Un código, todas estas pantallas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Terminal(
            lines: _devicesLines,
            title: 'zsh · mi máquina',
            fontSize: 22,
          ),
          const SizedBox(height: 40),
          Reveal(
            visible: step >= 1,
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Y además:',
                  style: DeckType.headline.copyWith(fontSize: 34, color: colors.ink),
                ),
                for (final target in const [
                  'Windows',
                  'Linux',
                  'Televisores',
                  'Tableros de carro',
                  'Kioscos',
                  'Juegos 2D con Flame',
                ])
                  Tag(target),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Reveal(
            visible: step >= 1,
            child: Text(
              '¿Tu nevera? Todavía no. Aunque Whirlpool ya usa Flutter en sus apps.',
              style: DeckType.small.copyWith(color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Casos reales del showcase oficial (flutter.dev/showcase).
class _WhereItLives extends StatelessWidget {
  const _WhereItLives();

  @override
  Widget build(BuildContext context) {
    const cards = [
      (Icons.account_balance, 'Bancos y fintech', 'Nubank · Crédit Agricole · SoFi · Virgin Money'),
      (Icons.auto_awesome, 'El propio Google', 'Google Pay · NotebookLM · Google Classroom · YouTube Create'),
      (Icons.directions_car, 'Carros', 'Toyota (tablero) · My BMW · Lucid Motors'),
      (Icons.tv, 'Televisores', 'LG: su plataforma webOS'),
      (Icons.desktop_windows, 'Escritorio', 'Ubuntu: el instalador y la tienda de apps'),
      (Icons.sports_esports, 'Entretenimiento', 'Universal Studios · Supercell ID · Headspace'),
    ];
    return SlideScaffold(
      title: 'Dónde vive Flutter',
      lead: 'Todos del showcase oficial. Nada de «mi primo hizo una app».',
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 2.05,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final (icon, title, examples) in cards)
            InfoCard(icon: icon, title: title, body: examples),
        ],
      ),
    );
  }
}
