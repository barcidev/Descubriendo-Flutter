import '../engine/slide.dart';
import 's00_doctor.dart';
import 's01_main.dart';
import 's02_version.dart';
import 's03_devices.dart';
import 's04_analyze.dart';
import 's05_build.dart';
import 's06_dart.dart';
import 's07_create.dart';
import 's08_pub_add.dart';
import 's09_run.dart';
import 's10_stdin.dart';
import 's11_q.dart';

/// La charla completa, en orden. Cada sección es un comando de Flutter.
List<Slide> buildDeck() => [
  ...doctorSlides,
  ...mainSlides,
  ...versionSlides,
  ...devicesSlides,
  ...analyzeSlides,
  ...buildSlides,
  ...dartSlides,
  ...createSlides,
  ...pubAddSlides,
  ...runSlides,
  ...stdinSlides,
  ...quitSlides,
];
