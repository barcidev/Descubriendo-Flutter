import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../engine/deck_scope.dart';
import '../engine/overview.dart';
import '../engine/slide.dart';
import '../live/join_card.dart';
import '../live/live_models.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/app_icon.dart';
import '../ui/blocks.dart';
import '../ui/reveal.dart';
import '../ui/slide_scaffold.dart';
import 'sections.dart';

/// Apps reales del showcase oficial (flutter.dev/showcase) mezcladas con
/// apps que no usan Flutter, más una trampa.
const builtWithFlutterPoll = PollSpec(
  id: 'hecha-con-flutter',
  question: '¿Cuáles están hechas con Flutter?',
  multiple: true,
  options: [
    PollOption(
      'gpay',
      'Google Pay',
      detail: 'Google la rehízo en Flutter para llegar a más países.',
      correct: true,
    ),
    PollOption(
      'nubank',
      'Nubank',
      detail: 'El banco digital escaló su app con Flutter.',
      correct: true,
    ),
    PollOption('whatsapp', 'WhatsApp', detail: 'Nativa en cada plataforma.'),
    PollOption(
      'bmw',
      'My BMW',
      detail: 'La app oficial de BMW para sus carros.',
      correct: true,
    ),
    PollOption('uber', 'Uber', detail: 'Nativa en cada plataforma.'),
    PollOption(
      'notebooklm',
      'NotebookLM',
      detail: 'La app de IA de Google: 4,8 estrellas, lista en 7 meses.',
      correct: true,
    ),
    PollOption('instagram', 'Instagram', detail: 'Nativa en cada plataforma.'),
    PollOption(
      'esta',
      'Esta presentación',
      detail: 'Sí: es una app de Flutter corriendo en Chrome.',
      correct: true,
    ),
  ],
);

/// El ícono de cada opción del quiz.
const _brands = {
  'gpay': AppBrand.googlePay,
  'nubank': AppBrand.nubank,
  'whatsapp': AppBrand.whatsapp,
  'bmw': AppBrand.bmw,
  'uber': AppBrand.uber,
  'notebooklm': AppBrand.notebookLm,
  'instagram': AppBrand.instagram,
  'esta': AppBrand.flutter,
};

final versionSlides = [
  Slide(
    id: 'una-frase',
    section: versionSection,
    title: 'Flutter en una frase',
    steps: 2,
    builder: (context, step) => _OneLiner(step: step),
  ),
  Slide(
    id: 'motor-de-videojuegos',
    section: versionSection,
    title: 'Un motor de videojuegos',
    steps: 3,
    builder: (context, step) => _Approaches(step: step),
  ),
  Slide(
    id: 'capas',
    section: versionSection,
    title: 'Las capas',
    skippable: true,
    builder: (context, step) => const _Layers(),
  ),
  Slide(
    id: 'linea-de-tiempo',
    section: versionSection,
    title: 'Línea de tiempo',
    skippable: true,
    builder: (context, step) => const _Timeline(),
  ),
  Slide(
    id: 'hecha-con-flutter',
    section: versionSection,
    title: '¿Hecha con Flutter?',
    steps: 3,
    cue: (step) => AudienceCue.poll(
      builtWithFlutterPoll,
      open: step == 0,
      revealed: step >= 1,
    ),
    builder: (context, step) => _BuiltWithFlutter(step: step),
  ),
];

class _OneLiner extends StatelessWidget {
  const _OneLiner({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Statement(
            'El SDK de Flutter es de código abierto, lo hace Google y sirve '
            'para crear apps de celular, web y escritorio con un solo código.',
            highlight: 'con un solo código.',
          ),
          const SizedBox(height: 56),
          Reveal(
            visible: step >= 1,
            child: Row(
              children: [
                Container(width: 6, height: 70, color: colors.accent),
                const SizedBox(width: 28),
                Text(
                  'En palabras sencillas: funciona en mi máquina… '
                  'y en todas las demás.',
                  style: DeckType.headline.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

/// Tres maneras de llegar a la pantalla: nativo, React Native y Flutter.
class _Approaches extends StatelessWidget {
  const _Approaches({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return SlideScaffold(
      title: 'Un motor de videojuegos que se equivocó de carrera',
      lead: 'Flutter no le pide botones al sistema: los dibuja, píxel por píxel.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Reveal(
              visible: true,
              child: _Approach(
                name: 'Nativo',
                boxes: const [
                  ('Kotlin', 'y aparte Swift'),
                  ('Componentes de Android', 'y los de iOS'),
                  ('Pantalla', null),
                ],
                verdict: 'Se ve 100 % nativo, pero lo haces dos veces.',
              ),
            ),
          ),
          const SizedBox(width: 48),
          Expanded(
            child: Reveal(
              visible: step >= 1,
              child: _Approach(
                name: 'React Native',
                boxes: const [
                  ('JavaScript', 'un solo código'),
                  ('Le pide componentes', 'a cada sistema'),
                  ('Pantalla', null),
                ],
                verdict: 'Un código, pero dependes de lo que cada sistema ofrece.',
              ),
            ),
          ),
          const SizedBox(width: 48),
          Expanded(
            child: Reveal(
              visible: step >= 2,
              child: _Approach(
                name: 'Flutter',
                highlight: true,
                boxes: const [
                  ('Dart', 'un solo código'),
                  ('Su propio motor: Impeller', 'como un videojuego'),
                  ('Pinta cada píxel', 'a 60 o 120 cuadros por segundo'),
                ],
                verdict: 'Un código y el mismo resultado en todas partes.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Approach extends StatelessWidget {
  const _Approach({
    required this.name,
    required this.boxes,
    required this.verdict,
    this.highlight = false,
  });

  final String name;
  final List<(String, String?)> boxes;
  final String verdict;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = highlight ? colors.accent : colors.line;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          name,
          style: DeckType.headline.copyWith(
            color: highlight ? colors.accentText : colors.ink,
          ),
        ),
        const SizedBox(height: 22),
        for (final (index, (title, detail)) in boxes.indexed) ...[
          Container(
            height: 112,
            padding: const EdgeInsets.symmetric(horizontal: 26),
            decoration: BoxDecoration(
              color: highlight && index == 1 ? colors.accent.withValues(alpha: 0.16) : colors.surface,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(color: border, width: highlight ? 2 : Space.hairline),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DeckType.small.copyWith(fontSize: 28, color: colors.ink)),
                if (detail != null)
                  Text(detail, style: DeckType.monoSmall.copyWith(color: colors.faint)),
              ],
            ),
          ),
          if (index < boxes.length - 1)
            SizedBox(
              height: 44,
              child: Icon(
                Icons.arrow_downward,
                color: highlight ? colors.accentText : colors.faint,
                size: 28,
              ),
            ),
        ],
        const SizedBox(height: 26),
        Text(verdict, style: DeckType.small.copyWith(color: colors.muted)),
      ],
    );
  }
}

class _Layers extends StatelessWidget {
  const _Layers();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget band(String name, String language, List<String> parts, Color tint) => Container(
      height: 168,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 36),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: tint.withValues(alpha: 0.55), width: Space.hairline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 330,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: DeckType.headline.copyWith(color: colors.ink)),
                const SizedBox(height: 6),
                Text(language, style: DeckType.monoSmall.copyWith(color: colors.faint)),
              ],
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final part in parts) Tag(part, color: colors.ink)],
            ),
          ),
        ],
      ),
    );
    return SlideScaffold(
      title: 'Las capas',
      lead: 'Tú escribes arriba. Lo demás viene en la caja.',
      child: Column(
        children: [
          band('Framework', 'Dart · lo que usas', const [
            'Material', 'Cupertino', 'Widgets', 'Rendering', 'Animación', 'Gestos',
          ], FlutterBrand.sky),
          band('Motor', 'C++ · lo que pinta', const [
            'Impeller', 'Texto', 'Dart runtime', 'Canales de plataforma',
          ], FlutterBrand.blue),
          band('Embedder', 'uno por plataforma', const [
            'Android', 'iOS', 'Web', 'Windows', 'macOS', 'Linux', 'Embebidos',
          ], FlutterBrand.navy),
        ],
      ),
    );
  }
}

const _milestones = [
  ('2015', '«Sky»', 'Dart en Android, apuntándole a 120 fps.'),
  ('2018', 'Flutter 1.0', 'La primera versión estable.'),
  ('2021', 'Flutter 2', 'Web estable.'),
  ('2022', 'Flutter 3', 'Escritorio estable.'),
  ('2023', 'Impeller', 'El motor nuevo, por defecto en iOS.'),
  ('2024', 'Wasm', 'WebAssembly estable; Impeller llega a Android.'),
  ('2025', 'Hot reload web', 'Estable desde la 3.35.'),
  ('2026', 'Flutter 3.47', 'Material y Cupertino como paquetes aparte.'),
];

class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'De experimento a SDK',
      lead: 'Once años, ocho hitos.',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 19,
                child: Container(height: 2, color: colors.line),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (index, (year, title, detail)) in _milestones.indexed)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: index == _milestones.length - 1
                                    ? colors.accent
                                    : colors.canvas,
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.accent, width: 3),
                              ),
                            ),
                            const SizedBox(height: 26),
                            Text(
                              year,
                              style: DeckType.monoLabel.copyWith(color: colors.accentText),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: DeckType.small.copyWith(fontSize: 28, color: colors.ink),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              detail,
                              style: DeckType.caption.copyWith(color: colors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuiltWithFlutter extends StatefulWidget {
  const _BuiltWithFlutter({required this.step});

  final int step;

  @override
  State<_BuiltWithFlutter> createState() => _BuiltWithFlutterState();
}

class _BuiltWithFlutterState extends State<_BuiltWithFlutter> {
  final _stack = GlobalKey();
  final _slot = GlobalKey();

  /// Dónde está la tarjeta de «Esta presentación» dentro de la diapositiva:
  /// de ahí sale para ir al centro.
  Rect? _slotRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(_BuiltWithFlutter oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final stack = _stack.currentContext?.findRenderObject() as RenderBox?;
    final slot = _slot.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || slot == null || !slot.hasSize) return;
    final rect = slot.localToGlobal(Offset.zero, ancestor: stack) & slot.size;
    if (rect != _slotRect) setState(() => _slotRect = rect);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    final step = widget.step;
    const poll = builtWithFlutterPoll;
    final trap = poll.options.last;
    return Stack(
      key: _stack,
      fit: StackFit.expand,
      children: [
        SlideScaffold(
          title: '¿Cuáles están hechas con Flutter?',
          lead: 'Marca todas las que creas. Sin googlear.',
          trailing: AnimatedOpacity(
            opacity: step == 0 ? 1 : 0.35,
            duration: Motion.base,
            child: const JoinCard(qrSize: 170, compact: true),
          ),
          child: ListenableBuilder(
            listenable: live,
            builder: (context, _) {
              final results = live.resultsFor(poll.id);
              final manual = !live.online && !live.simulating;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    // Las dos filas caben siempre, haya o no QR en el encabezado.
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const columns = 4;
                        const gap = 24.0;
                        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                        final height = (constraints.maxHeight - gap) / 2;
                        return GridView.count(
                          crossAxisCount: columns,
                          mainAxisSpacing: gap,
                          crossAxisSpacing: gap,
                          childAspectRatio: width / height,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (final (index, option) in poll.options.indexed)
                              if (option == trap)
                                // La trampa no se voltea aquí: se va al centro.
                                AnimatedOpacity(
                                  key: _slot,
                                  opacity: step >= 2 ? 0 : 1,
                                  duration: Motion.quick,
                                  child: QuizCard(
                                    index: index,
                                    option: option,
                                    brand: _brands[option.id]!,
                                    share: results.shareOf(option.id),
                                    votes: results.countOf(option.id),
                                    revealed: false,
                                    spotlight: false,
                                    dimmed: false,
                                  ),
                                )
                              else
                                QuizCard(
                                  index: index,
                                  option: option,
                                  brand: _brands[option.id]!,
                                  share: results.shareOf(option.id),
                                  votes: results.countOf(option.id),
                                  revealed: step >= 1,
                                  spotlight: false,
                                  dimmed: step >= 2,
                                ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 44,
                    child: AnimatedSwitcher(
                      duration: Motion.base,
                      child: Text(
                        switch (step) {
                          0 when manual => 'Mano alzada: teclas 1–8 suman votos',
                          0 => '${results.voters} personas ya votaron',
                          1 => 'Cuatro de siete. ¿Y la octava?',
                          _ => 'Estás viendo una app de Flutter. Oprime X y mírale los huesos.',
                        },
                        key: ValueKey(step),
                        style: DeckType.small.copyWith(
                          color: step >= 2 ? colors.accentText : colors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_slotRect case final slot?)
          ListenableBuilder(
            listenable: live,
            builder: (context, _) => _Spotlight(
              slot: slot,
              active: step >= 2,
              option: trap,
              brand: _brands[trap.id]!,
              share: live.resultsFor(poll.id).shareOf(trap.id),
              votes: live.resultsFor(poll.id).countOf(trap.id),
            ),
          ),
      ],
    );
  }
}

/// La tarjeta de «Esta presentación» sale de su lugar, crece en el centro
/// de la pantalla y ahí se voltea, para que se lea desde la última fila.
class _Spotlight extends StatelessWidget {
  const _Spotlight({
    required this.slot,
    required this.active,
    required this.option,
    required this.brand,
    required this.share,
    required this.votes,
  });

  final Rect slot;
  final bool active;
  final PollOption option;
  final AppBrand brand;
  final double share;
  final int votes;

  @override
  Widget build(BuildContext context) {
    final instant = Motion.reduced(context) || Thumbnail.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const zoom = 2.15;
        final size = slot.size * zoom;
        final target = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2 - 10),
          width: size.width,
          height: size.height,
        );
        return TweenAnimationBuilder<double>(
          tween: Tween(end: active ? 1 : 0),
          duration: instant ? Duration.zero : const Duration(milliseconds: 1700),
          builder: (context, t, _) {
            if (t == 0) return const SizedBox.shrink();
            // Primero viaja y crece; después se voltea.
            final travel = Motion.inOut.transform((t / 0.45).clamp(0, 1));
            final turn = Motion.inOut.transform(((t - 0.5) / 0.5).clamp(0, 1));
            final rect = Rect.lerp(slot, target, travel)!;
            final front = turn < 0.5;
            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: const Color(0xFF000000).withValues(alpha: 0.55 * travel),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: rect,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0009)
                      ..rotateY(turn * math.pi),
                    // La tarjeta se arma a su tamaño de la cuadrícula y se
                    // escala entera: crece igual que en el quiz.
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox.fromSize(
                        size: slot.size,
                        child: front
                            ? _Front(option: option, brand: brand, share: share, votes: votes, index: 7)
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: _Back(option: option, brand: brand, share: share, spotlight: true),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Una opción del quiz. Al revelar, se voltea y muestra el veredicto.
class QuizCard extends StatelessWidget {
  const QuizCard({
    required this.index,
    required this.option,
    required this.brand,
    required this.share,
    required this.votes,
    required this.revealed,
    required this.spotlight,
    required this.dimmed,
    super.key,
  });

  final int index;
  final PollOption option;
  final AppBrand brand;
  final double share;
  final int votes;
  final bool revealed;
  final bool spotlight;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final instant = Motion.reduced(context) || Thumbnail.of(context);
    // Se voltean en orden, una detrás de otra.
    const stagger = 110;
    final total = Duration(milliseconds: 620 + index * stagger);
    return AnimatedOpacity(
      opacity: dimmed ? 0.32 : 1,
      duration: Motion.base,
      child: AnimatedScale(
        scale: spotlight ? 1.06 : 1,
        duration: Motion.slow,
        curve: Motion.emphasized,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: revealed ? 1 : 0),
          duration: instant ? Duration.zero : total,
          curve: Interval(
            index * stagger / total.inMilliseconds,
            1,
            curve: Curves.easeInOutCubic,
          ),
          builder: (context, turn, _) {
            final front = turn < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(turn * math.pi),
              child: front
                  ? _Front(option: option, brand: brand, share: share, votes: votes, index: index)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: _Back(
                        option: option,
                        brand: brand,
                        share: share,
                        spotlight: spotlight,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({
    required this.option,
    required this.brand,
    required this.share,
    required this.votes,
    required this.index,
  });

  final PollOption option;
  final AppBrand brand;
  final double share;
  final int votes;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _CardShell(
      border: colors.line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // La trampa no se delata: de frente no lleva el logo de Flutter.
              AppIcon(brand == AppBrand.flutter ? AppBrand.slides : brand, size: 80),
              const Spacer(),
              Text(
                '${index + 1}',
                style: DeckType.monoSmall.copyWith(color: colors.faint),
              ),
            ],
          ),
          const Spacer(),
          Text(
            option.label,
            style: DeckType.headline.copyWith(fontSize: 38, color: colors.ink),
          ),
          const SizedBox(height: 16),
          _Bar(share: share, color: colors.accent, track: colors.line),
          const SizedBox(height: 10),
          Text(
            '${(share * 100).round()} %  ·  $votes',
            style: DeckType.monoSmall.copyWith(
              color: colors.muted,
              fontFeatures: DeckType.tabular,
            ),
          ),
        ],
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({
    required this.option,
    required this.brand,
    required this.share,
    required this.spotlight,
  });

  final PollOption option;
  final AppBrand brand;
  final double share;
  final bool spotlight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final yes = option.correct;
    final tone = yes ? colors.success : colors.faint;
    return _CardShell(
      border: spotlight ? colors.accent : (yes ? colors.success : colors.line),
      borderWidth: spotlight ? 3 : 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(brand, size: 44),
              const SizedBox(width: 16),
              Icon(yes ? Icons.check_circle : Icons.cancel, color: tone, size: 26),
              const SizedBox(width: 10),
              Text(
                yes ? 'Flutter' : 'No es Flutter',
                style: DeckType.monoLabel.copyWith(color: tone),
              ),
              const Spacer(),
              Text(
                '${(share * 100).round()} %',
                style: DeckType.monoSmall.copyWith(
                  color: colors.faint,
                  fontFeatures: DeckType.tabular,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            option.label,
            style: DeckType.headline.copyWith(fontSize: 34, color: colors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            option.detail ?? '',
            style: DeckType.caption.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    required this.border,
    this.borderWidth = 1.5,
  });

  final Widget child;
  final Color border;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: Motion.base,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: border, width: borderWidth),
      ),
      child: child,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.share, required this.color, required this.track});

  final double share;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: share),
              duration: Motion.slow,
              curve: Motion.emphasized,
              builder: (context, value, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
