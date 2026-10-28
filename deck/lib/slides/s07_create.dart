import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../demos/excusa_api.dart' as api;
import '../engine/deck_scope.dart';
import '../engine/overview.dart';
import '../engine/slide.dart';
import '../live/join_card.dart';
import '../live/live_controller.dart';
import '../live/live_models.dart';
import '../live/poll_view.dart';
import '../theme/deck_theme.dart';
import '../theme/tokens.dart';
import '../ui/blocks.dart';
import '../ui/code_block.dart';
import '../ui/highlighter.dart';
import '../ui/reveal.dart';
import '../ui/slide_scaffold.dart';
import '../ui/terminal.dart';
import 'sections.dart';

const themePoll = PollSpec(
  id: 'tema',
  question: '¿Claro u oscuro?',
  options: [
    PollOption('oscuro', 'Team oscuro'),
    PollOption('claro', 'Team claro (sí, existen)'),
  ],
);

final createSlides = [
  Slide(
    id: 'crear-proyecto',
    section: createSection,
    title: 'Pasos 1 y 2: instalar y crear',
    builder: (context, step) => const _CreateProject(),
  ),
  Slide(
    id: 'estructura',
    section: createSection,
    title: 'Paso 3: la estructura',
    builder: (context, step) => const _Structure(),
  ),
  Slide(
    id: 'api-kotlin',
    section: createSection,
    title: 'Paso 4: hablar con una API en Kotlin',
    steps: 4,
    builder: (context, step) => _KotlinApi(step: step),
  ),
  Slide(
    id: 'paquetes',
    section: createSection,
    title: 'Paso 5: paquetes',
    builder: (context, step) => const _Packages(),
  ),
  Slide(
    id: 'publicar',
    section: createSection,
    title: 'Paso 6: publicar (y el tema)',
    steps: 3,
    cue: (step) => AudienceCue.poll(themePoll, open: step == 0, revealed: step >= 1),
    builder: (context, step) => _Publish(step: step),
  ),
];

const _createLines = [
  TermLine.command('flutter doctor'),
  TermLine('[✓] Flutter (Channel stable, 3.47.8)', pause: Duration(milliseconds: 400)),
  TermLine('[✓] Android toolchain (Android SDK 36)'),
  TermLine('[✓] Xcode (para iOS y macOS)'),
  TermLine('[✓] Chrome'),
  TermLine('• No issues found!', tone: TermTone.success),
  TermLine.command('flutter create excusometro'),
  TermLine('Creating project excusometro...', pause: Duration(milliseconds: 500)),
  TermLine('All done!', tone: TermTone.success, pause: Duration(milliseconds: 600)),
];

const _anatomy = '''
excusometro/
├── lib/main.dart        tu app
├── test/                tus tests
├── android/  ios/       un proyecto nativo
├── web/  macos/         por plataforma
├── windows/  linux/
└── pubspec.yaml         como build.gradle.kts''';

class _CreateProject extends StatelessWidget {
  const _CreateProject();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'De cero a app en dos comandos',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Terminal(lines: _createLines, title: 'zsh · paso 1 y 2', fontSize: 22),
          ),
          const SizedBox(width: 56),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 26, 32, 26),
                  decoration: BoxDecoration(
                    color: CodeColors.background,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: CodeColors.border, width: Space.hairline),
                  ),
                  child: Text(
                    _anatomy,
                    style: DeckType.code.copyWith(fontSize: 23, color: CodeColors.plain),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'flutter doctor revisa que tengas todo; flutter create arma el '
                  'proyecto completo, con un ejemplo que ya corre.',
                  style: DeckType.small.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _structure = '''
lib/
├── main.dart
├── core/          red, sesión, errores
├── design/        tema, colores, componentes
└── features/
    └── excusas/
        ├── data/           cliente HTTP y modelos JSON
        ├── domain/         modelos y reglas
        ├── application/    estado
        └── presentation/   pantallas y widgets''';

class _Structure extends StatelessWidget {
  const _Structure();

  @override
  Widget build(BuildContext context) {
    return SlideScaffold(
      title: 'Ordenar por funcionalidad, no por tipo de archivo',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 26, 32, 26),
              decoration: BoxDecoration(
                color: CodeColors.background,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: CodeColors.border, width: Space.hairline),
              ),
              child: Text(
                _structure,
                style: DeckType.code.copyWith(fontSize: 24, color: CodeColors.plain),
              ),
            ),
          ),
          const SizedBox(width: 56),
          const Expanded(
            flex: 8,
            child: CompareTable(
              headers: ['Flutter', 'Si vienes de Spring'],
              mono: true,
              fontSize: 22,
              firstColumnFlex: 1,
              rows: [
                ['data', 'repository y cliente'],
                ['domain', 'entidades y reglas'],
                ['application', 'service'],
                ['presentation', 'controller y vista'],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _kotlinApi = '''
data class Excusa(
    val id: Int,
    val texto: String,
    val apodo: String,
)

@RestController
class ExcusaController(private val sala: SalaService) {

    @GetMapping("/excusas")
    fun elegidas(): List<Excusa> = sala.excusasElegidas()
}''';

/// El cliente en Dart, tal cual está en lib/demos/excusa_api.dart: es el
/// que hace la petición en vivo del último paso.
const _dartClient = '''
class Excusa {
  Excusa.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      texto = json['texto'] as String,
      apodo = json['apodo'] as String;

  final int id;
  final String texto;
  final String apodo;
}

Future<List<Excusa>> elegidas(Uri api) async {
  final res = await http.get(api.resolve('/excusas'));
  if (res.statusCode != 200) throw Exception('La API respondió \${res.statusCode}');
  final lista = jsonDecode(res.body) as List;
  return [for (final e in lista) Excusa.fromJson(e)];
}''';

/// El contrato de `GET /excusas`, con la primera excusa que salió en
/// pantalla en la diapositiva de las excusas.
String _contract(AudienceText excuse) =>
    '[{ "id": ${excuse.id}, "texto": ${jsonEncode(excuse.text)}, "apodo": "${excuse.author}" }, …]';

class _KotlinApi extends StatelessWidget {
  const _KotlinApi({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    return SlideScaffold(
      title: 'Flutter hablando con una API en Kotlin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(
            visible: step >= 1,
            child: Row(
              children: [
                Text('El contrato:', style: DeckType.small.copyWith(color: colors.muted)),
                const SizedBox(width: 20),
                Expanded(
                  child: CodeBlock(
                    code: _contract(live.shownExcuses.first),
                    language: CodeLang.typescript,
                    fileName: 'GET /excusas · JSON · el de verdad',
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: CodeBlock(
                    code: _kotlinApi,
                    language: CodeLang.kotlin,
                    fileName: 'servidor · ExcusaController.kt',
                    fontSize: 19,
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Motion.base,
                    child: switch (step) {
                      < 2 => Reveal(
                        key: const ValueKey('nada'),
                        visible: false,
                        child: const CodeBlock(code: _dartClient, fontSize: 18),
                      ),
                      2 => const CodeBlock(
                        key: ValueKey('dart'),
                        code: _dartClient,
                        fileName: 'app · excusa_api.dart',
                        fontSize: 18,
                      ),
                      _ => const _LiveRequest(key: ValueKey('vivo')),
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Una petición de verdad, con el cliente de la diapositiva: trae las
/// excusas que se eligieron hace un rato. Sin servidor, las mismas que se
/// vieron en pantalla, después de una espera de red.
class _LiveRequest extends StatefulWidget {
  const _LiveRequest({super.key});

  @override
  State<_LiveRequest> createState() => _LiveRequestState();
}

class _LiveRequestState extends State<_LiveRequest> {
  Future<(List<api.Excusa>, String)>? _request;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _load();
  }

  Future<(List<api.Excusa>, String)> _load() async {
    final live = DeckScope.of(context).live;
    List<api.Excusa> local() => [
      for (final excuse in live.shownExcuses)
        api.Excusa.fromJson({
          'id': int.tryParse(excuse.id) ?? 0,
          'texto': excuse.text,
          'apodo': excuse.author,
        }),
    ];
    if (Thumbnail.of(context)) return (local(), 'vista previa');
    final server = live.config.server;
    final watch = Stopwatch()..start();
    if (server != null && live.online) {
      try {
        final list = await api.elegidas(server).timeout(const Duration(seconds: 5));
        if (list.isNotEmpty) {
          return (list, 'GET /excusas · 200 · ${watch.elapsedMilliseconds} ms');
        }
      } on Object {
        // Sin red: el plan B también muestra lo mismo que se vio antes.
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return (local(), 'GET /excusas · 200 · ${watch.elapsedMilliseconds} ms');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: colors.accent, width: 2),
      ),
      child: FutureBuilder(
        future: _request,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return Row(
              children: [
                SizedBox.square(
                  dimension: 36,
                  child: CircularProgressIndicator(color: colors.accent, strokeWidth: 3),
                ),
                const SizedBox(width: 24),
                Text('FutureBuilder: cargando…', style: DeckType.body.copyWith(color: colors.muted)),
              ],
            );
          }
          final (items, status) = data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status, style: DeckType.monoSmall.copyWith(color: colors.success)),
              const SizedBox(height: 22),
              for (final excuse in items.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '«${excuse.texto}»  '),
                        TextSpan(
                          text: '${excuse.apodo}()',
                          style: DeckType.monoSmall.copyWith(color: colors.accentText),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DeckType.small.copyWith(fontSize: 26, color: colors.ink),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                'Las mismas que eligió la IA hace un rato: datos reales, de ustedes.',
                style: DeckType.small.copyWith(color: colors.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Dónde viven los paquetes: lo mismo que Maven Central o npm, con una nota
/// de calidad para cada uno.
class _Packages extends StatelessWidget {
  const _Packages();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'pub.dev: el Maven Central de Flutter',
      lead: 'Más de 81.000 paquetes. Y cada uno trae su nota.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CompareTable(
            headers: ['', 'Flutter · Dart', 'Java · Spring', 'Node'],
            highlightColumn: 1,
            fontSize: 22,
            firstColumnFlex: 0.85,
            rows: [
              ['Repositorio', 'pub.dev', 'Maven Central', 'npmjs.com'],
              ['Dependencias en', 'pubspec.yaml', 'build.gradle.kts · pom.xml', 'package.json'],
              ['Agregar una', 'flutter pub add dio', 'implementation("…")', 'npm install axios'],
              ['Versiones exactas', 'pubspec.lock', 'gradle.lockfile', 'package-lock.json'],
              ['Sello de confianza', 'publicador verificado', 'namespace verificado', 'provenance'],
            ],
          ),
          const SizedBox(height: 34),
          Text(
            'Lo que pub.dev le mide a cada paquete:',
            style: DeckType.monoLabel.copyWith(color: colors.accentText),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              Tag('Pub points: hasta 160, por análisis automático'),
              Tag('Likes y descargas'),
              Tag('Publicador verificado: dart.dev, google.dev…'),
              Tag('Flutter Favorite'),
              Tag('Plataformas que soporta'),
              Tag('Fecha de la última versión'),
            ],
          ),
        ],
      ),
    );
  }
}

const _publishLines = [
  TermLine.command('flutter build appbundle', pause: Duration(milliseconds: 300)),
  TermLine('✓ Built build/app/outputs/bundle/release/app-release.aab', tone: TermTone.success),
  TermLine.command('flutter build ipa'),
  TermLine('✓ Built IPA to build/ios/ipa', tone: TermTone.success),
  TermLine.command('flutter build web --wasm'),
  TermLine('✓ Built build/web', tone: TermTone.success),
];

/// El último paso y la votación del tema. Si gana el claro, la charla se
/// pone clara... por un paso: en el siguiente vuelve a la oscuridad, con
/// chiste incluido. Si gana el oscuro, se queda y se celebra.
class _Publish extends StatefulWidget {
  const _Publish({required this.step});

  final int step;

  @override
  State<_Publish> createState() => _PublishState();
}

class _PublishState extends State<_Publish> {
  @override
  void didUpdateWidget(_Publish oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step == oldWidget.step) return;
    final scope = DeckScope.of(context);
    // Al revelar, gana un tema y se aplica; en el chiste, vuelve el oscuro.
    final night = widget.step == 1 ? !_lightWon(scope.live) : true;
    WidgetsBinding.instance.addPostFrameCallback((_) => scope.deck.setNight(night));
  }

  bool _lightWon(LiveController live) {
    final results = live.resultsFor(themePoll.id);
    return results.countOf('claro') > results.countOf('oscuro');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = DeckScope.of(context).live;
    final step = widget.step;
    return SlideScaffold(
      title: 'Publicar: un comando por tienda',
      trailing: step == 0 ? const JoinCard(qrSize: 170, compact: true) : null,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                flex: 11,
                child: Terminal(lines: _publishLines, title: 'zsh · paso 6', fontSize: 22),
              ),
              const SizedBox(width: 48),
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Antes de irnos a la demo: ¿claro u oscuro?',
                      style: DeckType.headline.copyWith(fontSize: 36, color: colors.ink),
                    ),
                    const SizedBox(height: 24),
                    PollView(poll: themePoll, revealed: step >= 1, barHeight: 84, gap: 16),
                    const SizedBox(height: 22),
                    Reveal(
                      visible: step == 1,
                      child: Text(
                        'Un tema, toda la app: ThemeData.lerp interpola cada color.',
                        style: DeckType.small.copyWith(color: colors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (step >= 2)
            Positioned.fill(
              child: _ThemeJoke(lightWon: _lightWon(live)),
            ),
        ],
      ),
    );
  }
}

/// El chiste del final de la votación: si ganó el claro, el presentador
/// hace rollback; si ganó el oscuro, se celebra.
class _ThemeJoke extends StatelessWidget {
  const _ThemeJoke({required this.lightWon});

  final bool lightWon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (command, output, punchline, detail) = lightWon
        ? (
            'git revert tema-claro',
            '[main 5f0c1d2] Revert "tema claro": mis ojos no aprobaron el PR',
            'Democracia sí, pero esta charla es mía.',
            'Ganó el claro, y lo respeto. Desde lejos. Con gafas de sol. '
                'Volvemos al oscuro, como Dios y los devs mandan.',
          )
        : (
            'flutter analyze --tema',
            'No issues found! El modo oscuro gana por mayoría (y por salud visual).',
            '¿Por qué los devs usan modo oscuro?',
            'Porque la luz atrae a los bugs.',
          );
    return EnterOnce(
      child: Container(
        padding: const EdgeInsets.fromLTRB(56, 44, 56, 48),
        decoration: BoxDecoration(
          color: colors.canvas,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: colors.accent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 1300,
              child: Terminal(
                title: lightWon ? 'zsh · rollback' : 'zsh · veredicto',
                fontSize: 24,
                lines: [
                  TermLine.command(command, pause: const Duration(milliseconds: 300)),
                  TermLine(output, tone: TermTone.success, pause: const Duration(milliseconds: 500)),
                ],
              ),
            ),
            const SizedBox(height: 48),
            EnterOnce(
              delay: const Duration(milliseconds: 2600),
              child: Text(
                punchline,
                style: DeckType.display.copyWith(color: colors.ink),
              ),
            ),
            const SizedBox(height: 20),
            EnterOnce(
              delay: Duration(milliseconds: lightWon ? 3400 : 4200),
              child: Text(
                detail,
                style: DeckType.headline.copyWith(color: colors.accentText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
