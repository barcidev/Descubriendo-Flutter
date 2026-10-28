import '../engine/slide.dart';

// Cada sección es un comando real de Flutter. Los minutos suman 45.

const doctorSection = Section(
  command: 'flutter doctor',
  subtitle: 'Antes de empezar',
  minutes: 0,
);

const mainSection = Section(
  command: 'void main()',
  subtitle: 'Arranque',
  minutes: 2,
);

const versionSection = Section(
  command: 'flutter --version',
  subtitle: '¿Qué es Flutter?',
  minutes: 5,
);

const devicesSection = Section(
  command: 'flutter devices',
  subtitle: '¿Qué se puede hacer?',
  minutes: 3,
);

const analyzeSection = Section(
  command: 'flutter analyze',
  subtitle: '¿Cuándo sí y cuándo no?',
  minutes: 5,
);

const buildSection = Section(
  command: 'build(context)',
  subtitle: '¿Cómo se programa?',
  minutes: 8,
);

const migrateSection = Section(
  command: 'dart migrate',
  subtitle: 'Dart y sus primos',
  minutes: 5,
);

const createSection = Section(
  command: 'flutter create',
  subtitle: 'Construir una app',
  minutes: 6,
);

const pubAddSection = Section(
  command: 'flutter pub add buenas_practicas',
  subtitle: 'Recomendaciones',
  minutes: 3,
);

const runSection = Section(
  command: 'flutter run',
  subtitle: 'La demo',
  minutes: 3,
);

const stdinSection = Section(
  command: 'stdin',
  subtitle: 'Preguntas',
  minutes: 4,
);

const quitSection = Section(command: 'q', subtitle: 'Cierre', minutes: 1);
