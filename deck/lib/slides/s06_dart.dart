import 'package:material_ui/material_ui.dart';

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
import 'sections.dart';

const whichIsDartPoll = PollSpec(
  id: 'cual-es-dart',
  question: '¿Cuál de los cuatro es Dart?',
  options: [
    PollOption('a', 'A'),
    PollOption('b', 'B', correct: true),
    PollOption('c', 'C'),
    PollOption('d', 'D'),
  ],
);

final dartSlides = [
  Slide(
    id: 'dart-en-60',
    section: migrateSection,
    title: 'Dart en 60 segundos',
    steps: 4,
    builder: (context, step) => _DartIn60(step: step),
  ),
  Slide(
    id: 'cual-es-dart',
    section: migrateSection,
    title: '¿Cuál es Dart?',
    steps: 2,
    cue: (step) => AudienceCue.poll(whichIsDartPoll, open: step == 0, revealed: step >= 1),
    builder: (context, step) => _WhichIsDart(step: step),
  ),
  Slide(
    id: 'pantalla-roja',
    section: migrateSection,
    title: 'La pantalla roja',
    steps: 2,
    chrome: false,
    // Los celulares también «revientan» y, en el paso 2, se arreglan.
    cue: (step) => AudienceCue.crash(fixed: step >= 1),
    builder: (context, step) => _RedScreen(step: step),
  ),
  Slide(
    id: 'flutter-y-sus-primos',
    section: migrateSection,
    title: 'Flutter y sus primos',
    builder: (context, step) => const _Cousins(),
  ),
  Slide(
    id: 'misma-tarjeta',
    section: migrateSection,
    title: 'La misma tarjeta, cuatro veces',
    steps: 4,
    builder: (context, step) => _SameCard(step: step),
  ),
];

const _dartTour = '''
class Excusa {
  const Excusa(this.texto, {this.creible = false});
  final String texto;
  final bool creible;
}

Future<List<Excusa>> cargar() async {
  final respuesta = await http.get(Uri.parse('\$api/excusas'));
  final lista = jsonDecode(respuesta.body) as List;
  return [for (final e in lista) Excusa(e['texto'] as String)];
}

String resumen(List<Excusa> excusas) {
  final primera = excusas.firstOrNull?.texto ?? 'ninguna';
  final (total, creibles) =
      (excusas.length, excusas.where((e) => e.creible).length);
  return '\$total excusas, \$creibles creíbles. La primera: \$primera';
}''';

const _tourNotes = [
  ('Clases y tipos', 'Constructores cortos, parámetros con nombre, final como val.', {1, 2, 3, 4, 5}),
  ('async / await', 'Future es la promesa de un valor. Igual que suspend o Promise.', {7, 8, 9, 10, 11}),
  ('Null safety', '?. y ?? : si puede ser nulo, el compilador te obliga a decidir.', {14}),
  ('Records y colecciones', 'Tuplas con desestructuración y for/if dentro de las listas.', {10, 15, 16}),
];

class _DartIn60 extends StatelessWidget {
  const _DartIn60({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final note = _tourNotes[step];
    return SlideScaffold(
      title: 'Dart: no lo conocías, pero ya lo sabes leer',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 13,
            child: CodeBlock(
              code: _dartTour,
              fileName: 'excusas.dart',
              fontSize: 21,
              focus: note.$3,
            ),
          ),
          const SizedBox(width: 56),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step + 1} / ${_tourNotes.length}',
                  style: DeckType.monoLabel.copyWith(color: colors.accentText),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: Motion.base,
                  child: Column(
                    key: ValueKey(step),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.$1, style: DeckType.title.copyWith(color: colors.ink)),
                      const SizedBox(height: 18),
                      Text(note.$2, style: DeckType.body.copyWith(color: colors.muted)),
                    ],
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

const _snippets = [
  ('A', 'Swift', CodeLang.swift, 'let creibles = excusas.filter { \$0.creible }'),
  ('B', 'Dart', CodeLang.dart, 'final creibles = excusas.where((e) => e.creible).toList();'),
  ('C', 'TypeScript', CodeLang.typescript, 'const creibles = excusas.filter(e => e.creible);'),
  ('D', 'Kotlin', CodeLang.kotlin, 'val creibles = excusas.filter { it.creible }'),
];

class _WhichIsDart extends StatelessWidget {
  const _WhichIsDart({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final revealed = step >= 1;
    return SlideScaffold(
      title: '¿Cuál de los cuatro es Dart?',
      lead: 'Los cuatro filtran las excusas creíbles.',
      trailing: revealed ? null : const JoinCard(qrSize: 170, compact: true),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 14,
            child: Column(
              children: [
                for (final (letter, language, lang, code) in _snippets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AnimatedOpacity(
                      duration: Motion.base,
                      opacity: revealed && letter != 'B' ? 0.45 : 1,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: Text(
                              letter,
                              style: DeckType.title.copyWith(
                                color: revealed && letter == 'B'
                                    ? colors.success
                                    : colors.accentText,
                              ),
                            ),
                          ),
                          Expanded(
                            child: CodeBlock(
                              code: code,
                              language: lang,
                              fileName: revealed ? language : '¿?',
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 48),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PollView(poll: whichIsDartPoll, revealed: revealed, barHeight: 64, gap: 12),
                const SizedBox(height: 28),
                Reveal(
                  visible: revealed,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Y el resultado, en los cuatro: '),
                        TextSpan(
                          text: '[]',
                          style: DeckType.mono.copyWith(color: colors.accentText),
                        ),
                        const TextSpan(text: '\nNinguna excusa es creíble.'),
                      ],
                    ),
                    style: DeckType.body.copyWith(color: colors.muted),
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

/// La pantalla roja de error de Flutter… a propósito.
class _RedScreen extends StatelessWidget {
  const _RedScreen({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFFFFF66);
    const mono = TextStyle(
      fontFamily: DeckFonts.mono,
      fontSize: 30,
      height: 1.5,
      color: yellow,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(
          color: Color(0xFFD00000),
          child: Padding(
            padding: EdgeInsets.fromLTRB(120, 140, 120, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Null check operator used on a null value',
                  style: TextStyle(
                    fontFamily: DeckFonts.mono,
                    fontSize: 54,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: yellow,
                  ),
                ),
                SizedBox(height: 48),
                Text(
                  'The relevant error-causing widget was:\n'
                  '  Charla  lib/charla.dart:42:13\n\n'
                  'When the exception was thrown, this was the stack:\n'
                  '#0      _CharlaState.build (package:charla/charla.dart:57:24)\n'
                  '#1      StatefulElement.build (package:flutter/src/widgets/framework.dart)\n'
                  '#2      ComponentElement.performRebuild (package:flutter/…)',
                  style: mono,
                ),
              ],
            ),
          ),
        ),
        Reveal(
          visible: step >= 1,
          from: const Offset(0, 0.04),
          child: const _NullSafety(),
        ),
      ],
    );
  }
}

const _nullSafety = '''
String? excusa;                          // puede ser nula: el tipo lo dice

excusa?.length                           // si es nula, no revienta: da null
excusa ?? 'Funciona en mi máquina'       // valor por defecto
excusa!                                  // «confía en mí»: la pantalla roja''';

class _NullSafety extends StatelessWidget {
  const _NullSafety();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.pageX, 110, Space.pageX, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tranquilos: era parte del show.',
              style: DeckType.title.copyWith(color: colors.ink),
            ),
            const SizedBox(height: 14),
            Text(
              'Ese «!» le dijo al compilador «confía en mí». Null safety existe '
              'para no tener que decirlo.',
              style: DeckType.headline.copyWith(fontSize: 36, color: colors.muted),
            ),
            const SizedBox(height: 40),
            const CodeBlock(code: _nullSafety, fileName: 'null_safety.dart', fontSize: 26),
            const SizedBox(height: 36),
            Row(
              children: [
                Container(width: 6, height: 64, color: colors.accent),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    '«Lo llamo mi error de mil millones de dólares: la referencia '
                    'nula.» — Tony Hoare, 2009. En Kotlin es ?. y ?: ; en Dart, ?. y ??.',
                    style: DeckType.small.copyWith(color: colors.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Cousins extends StatelessWidget {
  const _Cousins();

  @override
  Widget build(BuildContext context) {
    return const SlideScaffold(
      title: 'Flutter y sus primos',
      lead: 'Todos llegaron a la misma idea: la UI se declara.',
      child: CompareTable(
        headers: ['', 'React', 'SwiftUI', 'Jetpack Compose', 'Flutter'],
        highlightColumn: 4,
        fontSize: 21,
        firstColumnFlex: 0.9,
        rows: [
          ['La pieza', 'Componente', 'View', '@Composable', 'Widget'],
          ['Estado local', 'useState', '@State', 'remember', 'setState'],
          ['Estado compartido', 'Context · Redux', '@Observable', 'ViewModel · StateFlow', 'Riverpod · Bloc'],
          ['Layout', 'Flexbox', 'HStack · VStack', 'Row · Column', 'Row · Column'],
          ['Listas largas', 'FlatList', 'List', 'LazyColumn', 'ListView.builder'],
          ['Estilos', 'CSS', 'Modificadores', 'Modifier', 'Widgets y Theme'],
          ['Ver cambios al vuelo', 'Fast Refresh', 'Previews', 'Live Edit', 'Hot reload'],
        ],
      ),
    );
  }
}

const _sameCard = [
  (
    'Flutter',
    'excusa.dart',
    CodeLang.dart,
    '''
Card(
  child: Column(
    children: [
      Text(excusa),
      FilledButton(
        onPressed: otraExcusa,
        child: Text('Otra excusa'),
      ),
    ],
  ),
)''',
  ),
  (
    'Compose',
    'Excusa.kt',
    CodeLang.kotlin,
    '''
Card {
    Column {
        Text(excusa)
        Button(
            onClick = { otraExcusa() },
        ) {
            Text("Otra excusa")
        }
    }
}''',
  ),
  (
    'SwiftUI',
    'Excusa.swift',
    CodeLang.swift,
    '''
VStack {
    Text(excusa)
    Button("Otra excusa") {
        otraExcusa()
    }
}
.padding()
.background(.background)''',
  ),
  (
    'React',
    'Excusa.jsx',
    CodeLang.jsx,
    '''
<Card>
  <p>{excusa}</p>
  <button onClick={otraExcusa}>
    Otra excusa
  </button>
</Card>''',
  ),
];

class _SameCard extends StatelessWidget {
  const _SameCard({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (_, file, language, code) = _sameCard[step];
    return SlideScaffold(
      title: 'La misma tarjeta, cuatro veces',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepTabs(labels: [for (final (name, _, _, _) in _sameCard) name], selected: step),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: CodeBlock(
                  key: ValueKey(step),
                  code: code,
                  language: language,
                  fileName: file,
                  fontSize: 26,
                  minLines: 11,
                ),
              ),
              const SizedBox(width: 56),
              Expanded(
                flex: 2,
                child: Text(
                  switch (step) {
                    0 => 'Widgets dentro de widgets. Los paréntesis cierran todo.',
                    1 => 'Casi igual: Compose y Flutter son primos hermanos.',
                    2 => 'SwiftUI: la misma idea con modificadores.',
                    _ => 'React: la misma idea con etiquetas.',
                  },
                  style: DeckType.headline.copyWith(fontSize: 38, color: colors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
