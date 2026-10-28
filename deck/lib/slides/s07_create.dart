import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../demos/excusometro.dart';
import '../engine/deck_scope.dart';
import '../engine/overview.dart';
import '../engine/slide.dart';
import '../live/join_card.dart';
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
    id: 'estado',
    section: createSection,
    title: 'Paso 4: el estado',
    builder: (context, step) => const _StateManagement(),
  ),
  Slide(
    id: 'api-kotlin',
    section: createSection,
    title: 'Paso 5: hablar con una API en Kotlin',
    steps: 4,
    builder: (context, step) => _KotlinApi(step: step),
  ),
  Slide(
    id: 'errores-tipados',
    section: createSection,
    title: 'Cuando la API falla',
    builder: (context, step) => const _TypedFailures(),
  ),
  Slide(
    id: 'navegacion-paquetes',
    section: createSection,
    title: 'Pasos 6 y 7: rutas y paquetes',
    builder: (context, step) => const _RoutesAndPackages(),
  ),
  Slide(
    id: 'tests',
    section: createSection,
    title: 'Paso 8: tests',
    builder: (context, step) => const _Tests(),
  ),
  Slide(
    id: 'publicar',
    section: createSection,
    title: 'Paso 9: publicar (y el tema)',
    steps: 2,
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

const _riverpod = '''
@riverpod
Future<List<Excusa>> excusas(Ref ref) =>
    ref.watch(apiProvider).listar();

class ListaDeExcusas extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(excusasProvider).when(
      data: (lista) => ExcuseList(lista),
      loading: () => const CircularProgressIndicator(),
      error: (falla, _) => Text(mensaje(falla)),
    );
  }
}''';

class _StateManagement extends StatelessWidget {
  const _StateManagement();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'Cuando la app crece, el estado sale del widget',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 12,
            child: CodeBlock(code: _riverpod, fileName: 'excusas_provider.dart', fontSize: 22),
          ),
          const SizedBox(width: 56),
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'setState alcanza para una pantalla. Para una app: un gestor.',
                  style: DeckType.headline.copyWith(fontSize: 34, color: colors.ink),
                ),
                const SizedBox(height: 28),
                const Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [Tag('Provider'), Tag('Riverpod'), Tag('Bloc'), Tag('Signals')],
                ),
                const SizedBox(height: 28),
                Text(
                  'Riverpod se parece a inyección de dependencias más estado '
                  'reactivo: un Spring chiquito con StateFlow. Elige uno y sé '
                  'consistente.',
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

const _kotlinApi = '''
data class Excusa(
    val id: Long,
    val texto: String,
    val creible: Boolean,
)

@RestController
@RequestMapping("/api/excusas")
class ExcusaController(private val servicio: ExcusaService) {

    @GetMapping
    fun listar(): List<Excusa> = servicio.todas()
}''';

const _json = '''
[{ "id": 1, "texto": "Es un tema de caché", "creible": false }]''';

const _dartClient = '''
class Excusa {
  Excusa.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      texto = json['texto'] as String,
      creible = json['creible'] as bool;
  final int id;
  final String texto;
  final bool creible;
}

Future<List<Excusa>> listar() async {
  final res = await http.get(Uri.parse('\$api/api/excusas'));
  final lista = jsonDecode(res.body) as List;
  return [for (final e in lista) Excusa.fromJson(e)];
}''';

class _KotlinApi extends StatelessWidget {
  const _KotlinApi({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                const Expanded(
                  child: CodeBlock(code: _json, language: CodeLang.typescript, fileName: 'GET /api/excusas · JSON', fontSize: 21),
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
                        child: const CodeBlock(code: _dartClient, fontSize: 19),
                      ),
                      2 => const CodeBlock(
                        key: ValueKey('dart'),
                        code: _dartClient,
                        fileName: 'app · excusa_api.dart',
                        fontSize: 19,
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

/// Una petición de verdad, desde esta charla al servidor de votaciones:
/// la demo de FutureBuilder con datos que escribió el público.
class _LiveRequest extends StatefulWidget {
  const _LiveRequest({super.key});

  @override
  State<_LiveRequest> createState() => _LiveRequestState();
}

class _LiveRequestState extends State<_LiveRequest> {
  Future<(List<String>, String)>? _request;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _load();
  }

  Future<(List<String>, String)> _load() async {
    if (Thumbnail.of(context)) return (excuses.take(3).toList(), 'vista previa');
    final uri = DeckScope.of(context).live.config.excuses;
    final watch = Stopwatch()..start();
    if (uri != null) {
      try {
        final response = await http.get(uri).timeout(const Duration(seconds: 4));
        final list = [
          for (final item in jsonDecode(response.body) as List)
            (item as Map)['text'] as String,
        ];
        return (
          list.isEmpty ? excuses.take(3).toList() : list.take(4).toList(),
          'GET ${uri.path} · ${response.statusCode} · ${watch.elapsedMilliseconds} ms',
        );
      } on Object {
        // Sin red: el plan B también es una demo de manejo de errores.
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return (excuses.take(3).toList(), 'sin servidor · datos locales');
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
              for (final excuse in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text('«$excuse»', style: DeckType.body.copyWith(color: colors.ink)),
                ),
              const SizedBox(height: 10),
              Text(
                'Datos reales: excusas que mandaron ustedes hace un rato.',
                style: DeckType.small.copyWith(color: colors.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}

const _dartFailures = '''
sealed class Falla {}
class SinConexion extends Falla {}
class NoAutorizado extends Falla {}
class Saturado extends Falla {
  Saturado(this.reintentarEn);
  final Duration reintentarEn;
}

String mensaje(Falla falla) => switch (falla) {
  SinConexion() => 'Revisa tu conexión',
  NoAutorizado() => 'Tu sesión venció',
  Saturado(:final reintentarEn) =>
      'Espera \${reintentarEn.inSeconds} s',
};''';

const _kotlinFailures = '''
sealed interface Falla
data object SinConexion : Falla
data object NoAutorizado : Falla
data class Saturado(
    val reintentarEn: Duration,
) : Falla

fun mensaje(falla: Falla) = when (falla) {
    SinConexion -> "Revisa tu conexión"
    NoAutorizado -> "Tu sesión venció"
    is Saturado ->
        "Espera \${falla.reintentarEn.inWholeSeconds} s"
}''';

class _TypedFailures extends StatelessWidget {
  const _TypedFailures();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'Cuando la API falla: errores con tipo',
      lead: '401, 429, sin red: cada uno es un caso. Si olvidas uno, no compila.',
      child: Column(
        children: [
          const Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: CodeBlock(code: _dartFailures, fileName: 'falla.dart', fontSize: 20)),
                SizedBox(width: 32),
                Expanded(
                  child: CodeBlock(
                    code: _kotlinFailures,
                    language: CodeLang.kotlin,
                    fileName: 'Falla.kt',
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Mismo patrón, dos lenguajes: sealed + switch en Dart, sealed + when en Kotlin.',
            style: DeckType.small.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

const _router = '''
final rutas = GoRouter(routes: [
  GoRoute(path: '/', builder: (_, _) => const Inicio()),
  GoRoute(
    path: '/excusa/:id',
    builder: (_, estado) =>
        Detalle(id: estado.pathParameters['id']!),
  ),
]);

// Y para navegar:
context.go('/excusa/42');''';

class _RoutesAndPackages extends StatelessWidget {
  const _RoutesAndPackages();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'Rutas y paquetes',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 11,
            child: CodeBlock(code: _router, fileName: 'rutas.dart · go_router', fontSize: 22),
          ),
          const SizedBox(width: 48),
          Expanded(
            flex: 8,
            child: InfoCard(
              icon: Icons.inventory_2_outlined,
              title: 'pub.dev: 81.705 paquetes',
              body: 'Antes de agregar uno, mira:',
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final check in const [
                      'Likes y descargas',
                      'Pub points: de 160 posibles',
                      'Publicador verificado',
                      'Última versión reciente',
                      'Las plataformas que necesitas',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.check, color: colors.success, size: 26),
                            const SizedBox(width: 14),
                            Text(check, style: DeckType.small.copyWith(color: colors.ink)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _widgetTest = '''
testWidgets('Otra excusa cambia el texto', (tester) async {
  await tester.pumpWidget(const Excusometro());
  expect(find.text('Funciona en mi máquina.'), findsOneWidget);

  await tester.tap(find.text('Otra excusa'));
  await tester.pump();

  expect(find.text('Funciona en mi máquina.'), findsNothing);
  expect(find.text('Fue culpa mía.'), findsNothing); // nunca pasa
});''';

class _Tests extends StatelessWidget {
  const _Tests();

  @override
  Widget build(BuildContext context) {
    return const SlideScaffold(
      title: 'Tests: sin celular y en milisegundos',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 13,
            child: CodeBlock(code: _widgetTest, fileName: 'test/excusometro_test.dart', fontSize: 21),
          ),
          SizedBox(width: 48),
          Expanded(
            flex: 6,
            child: PointList(
              gap: 22,
              points: [
                ('Unitarios', 'Tu lógica, sin Flutter. Los más rápidos.'),
                ('De widget', 'La UI completa, sin dispositivo.'),
                ('De integración', 'En el celular o el emulador de verdad.'),
              ],
            ),
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
    // Al revelar, la charla obedece al público: gana un tema y se aplica.
    if (widget.step >= 1 && oldWidget.step == 0) {
      final scope = DeckScope.of(context);
      final results = scope.live.resultsFor(themePoll.id);
      final light = results.countOf('claro') > results.countOf('oscuro');
      WidgetsBinding.instance.addPostFrameCallback((_) => scope.deck.setNight(!light));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SlideScaffold(
      title: 'Publicar: un comando por tienda',
      trailing: widget.step == 0 ? const JoinCard(qrSize: 170, compact: true) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 11,
            child: Terminal(lines: _publishLines, title: 'zsh · paso 9', fontSize: 22),
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
                PollView(poll: themePoll, revealed: widget.step >= 1, barHeight: 84, gap: 16),
                const SizedBox(height: 22),
                Reveal(
                  visible: widget.step >= 1,
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
    );
  }
}
