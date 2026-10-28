import 'package:flutter/foundation.dart';

import 'slide.dart';

/// Dónde va la charla: diapositiva, paso dentro de ella y los modos de
/// pantalla (rayos X, pausa, vista general, tema).
class DeckController extends ChangeNotifier {
  DeckController(this.slides, {int index = 0, int step = 0})
    : assert(slides.isNotEmpty) {
    _index = index.clamp(0, slides.length - 1);
    _step = step.clamp(0, slides[_index].steps - 1);
  }

  final List<Slide> slides;

  late int _index;
  late int _step;
  int _direction = 1;
  bool _xray = false;
  bool _paused = false;
  bool _overview = false;
  bool _night = true;
  bool _qr = false;
  bool _reactions = true;

  int get index => _index;
  int get step => _step;
  Slide get slide => slides[_index];

  /// 1 si la última vez se avanzó, -1 si se retrocedió.
  int get direction => _direction;
  bool get xray => _xray;
  bool get paused => _paused;
  bool get overview => _overview;
  bool get night => _night;

  /// El QR gigante encima de todo, para el fondo del auditorio.
  bool get qr => _qr;

  /// Las reacciones del público flotando en pantalla.
  bool get reactions => _reactions;

  bool get isFirst => _index == 0 && _step == 0;
  bool get isLast => _index == slides.length - 1 && _step == slide.steps - 1;

  /// Las secciones en orden, sin repetir.
  late final List<Section> sections = [
    for (final (index, slide) in slides.indexed)
      if (index == 0 || slides[index - 1].section != slide.section)
        slide.section,
  ];

  int sectionIndexOf(int slideIndex) =>
      sections.indexOf(slides[slideIndex].section);

  bool startsSection(int slideIndex) =>
      slideIndex == 0 ||
      slides[slideIndex - 1].section != slides[slideIndex].section;

  void next() {
    if (_paused) return _setPaused(false);
    if (_step < slide.steps - 1) {
      _step++;
    } else if (_index < slides.length - 1) {
      _index++;
      _step = 0;
      _direction = 1;
    } else {
      return;
    }
    notifyListeners();
  }

  void previous() {
    if (_paused) return _setPaused(false);
    if (_step > 0) {
      _step--;
    } else if (_index > 0) {
      _index--;
      _step = slide.steps - 1;
      _direction = -1;
    } else {
      return;
    }
    notifyListeners();
  }

  /// Salta a una diapositiva. Sin paso, llega al primero.
  void goTo(int index, {int step = 0}) {
    final target = index.clamp(0, slides.length - 1);
    final targetStep = step.clamp(0, slides[target].steps - 1);
    if (target == _index && targetStep == _step) return;
    _direction = target >= _index ? 1 : -1;
    _index = target;
    _step = targetStep;
    _overview = false;
    notifyListeners();
  }

  void toggleXray() {
    _xray = !_xray;
    notifyListeners();
  }

  void togglePause() => _setPaused(!_paused);

  void toggleOverview() {
    _overview = !_overview;
    notifyListeners();
  }

  void toggleTheme() => setNight(!_night);

  void toggleQr() {
    _qr = !_qr;
    notifyListeners();
  }

  void toggleReactions() {
    _reactions = !_reactions;
    notifyListeners();
  }

  void setNight(bool night) {
    if (night == _night) return;
    _night = night;
    notifyListeners();
  }

  void _setPaused(bool paused) {
    _paused = paused;
    notifyListeners();
  }

  /// Posición en la URL, contando desde 1: `/12/2`.
  String get hash => '/${_index + 1}/${_step + 1}';

  /// Lee `/12/2` (o `/12`) y devuelve índice y paso desde 0.
  static (int, int)? parseHash(String fragment) {
    final parts = fragment
        .split('/')
        .where((part) => part.isNotEmpty)
        .map(int.tryParse)
        .toList();
    if (parts.isEmpty || parts.first == null) return null;
    final index = parts.first! - 1;
    final step = parts.length > 1 && parts[1] != null ? parts[1]! - 1 : 0;
    return (index, step);
  }
}
