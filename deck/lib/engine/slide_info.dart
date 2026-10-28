import 'package:flutter/widgets.dart';

import 'slide.dart';

/// La diapositiva a la que pertenece un widget, aunque en ese momento la
/// charla vaya en otra (durante una transición o en la vista general).
class SlideInfo extends InheritedWidget {
  const SlideInfo({
    required this.slide,
    required this.startsSection,
    required super.child,
    super.key,
  });

  final Slide slide;

  /// Es la primera de su sección: el comando se escribe al entrar.
  final bool startsSection;

  static SlideInfo? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SlideInfo>();

  @override
  bool updateShouldNotify(SlideInfo oldWidget) =>
      slide != oldWidget.slide || startsSection != oldWidget.startsSection;
}
