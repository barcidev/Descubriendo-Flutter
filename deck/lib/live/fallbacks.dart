import 'dart:math' as math;

import 'live_models.dart';

/// El plan B de las excusas cuando no hay servidor: las mismas que tiene el
/// servidor (servidor/lib/jurado.dart), escritas como las escribiría el
/// público de Barranquilla, cada una con su apodo de widget.
const backupExcuses = [
  ('Se fue la luz en todo el barrio y Air-e no ha dicho nada', 'SafeArea'),
  ('el arroyo de la 21 no me dejó llegar a la daily', 'Expanded'),
  ('La brisa me cerró la tapa del portátil en pleno deploy', 'Opacity'),
  ('No hice el commit porque estaba jugando el Junior', 'StreamBuilder'),
  ('es que el compilador no entiende costeño', 'Text'),
  ('Ajá y yo qué sé, en el emulador sí servía', 'FutureBuilder'),
  ('Estaba esperando que bajara el calor pa programar', 'Spacer'),
  ('le di flutter clean y se borró hasta la fe', 'SingleChildScrollView'),
  ('Hice el deploy un viernes y me fui pa Puerto Colombia', 'Hero'),
  ('Me quedé sin datos en el Transmetro y no pude hacer push', 'Flexible'),
  ('Mi mamá me llamó a almorzar y un sancocho no se deja enfriar', 'Card'),
  ('ese bug se metió por la ventana con la brisa', 'GestureDetector'),
  ('eso es tema de caché, eche', 'Padding'),
  ('ChatGPT me dijo que así era', 'Placeholder'),
  ('Funciona en mi máquina, el problema es que mi máquina está en Soledad', 'Row'),
  ('era sábado de carnaval, eso no cuenta como día hábil', 'AnimatedContainer'),
];

/// [count] excusas de respaldo al azar, con ids como los del servidor.
List<AudienceText> pickBackupExcuses(math.Random random, {int count = 5}) {
  final indices = [for (var i = 0; i < backupExcuses.length; i++) i]
    ..shuffle(random);
  return [
    for (final i in indices.take(count))
      AudienceText(
        id: '${900 + i}',
        text: backupExcuses[i].$1,
        author: backupExcuses[i].$2,
        approved: true,
      ),
  ];
}

/// Para ensayar sin público: preguntas típicas de una charla de Flutter.
const rehearsalQuestions = [
  ('¿Flutter sirve para hacer páginas web normales o solo apps?', 'Expanded'),
  ('¿Qué tan difícil es pasar de Kotlin o Java a Dart?', 'Padding'),
  ('¿Qué gestor de estado recomiendas para empezar?', 'Stack'),
  ('¿Las apps de Flutter pesan más que las nativas?', 'Hero'),
  ('¿Cómo se accede a la cámara o al GPS desde Flutter?', 'SafeArea'),
];

/// Nombres de mentira para ensayar la terminal y los créditos.
const rehearsalNames = [
  'Valentina', 'Andrés', 'Camila', 'Santiago', 'Daniela', 'Sebastián',
  'María José', 'Juan David', 'Laura', 'Carlos', 'Mariana', 'Alejandro',
  'Isabella', 'Mateo', 'Sofía', 'Luis Fernando', 'Natalia', 'Diego',
  'Paula', 'Jesús', 'Karen', 'Óscar', 'Yuliana', 'Kevin',
];

/// Los mismos widgets que reparte el servidor, para los apodos de ensayo.
const rehearsalWidgets = [
  'Expanded', 'Padding', 'Spacer', 'Stack', 'Center', 'Hero',
  'FutureBuilder', 'StreamBuilder', 'SafeArea', 'Opacity', 'GestureDetector',
  'AnimatedContainer', 'Card', 'Wrap', 'Flexible', 'ListView',
  'InheritedWidget', 'Scaffold', 'AspectRatio', 'ClipRRect', 'Tooltip',
  'RepaintBoundary', 'SingleChildScrollView', 'SnackBar',
];
