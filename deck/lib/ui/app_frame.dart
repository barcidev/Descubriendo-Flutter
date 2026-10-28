import 'package:flutter/widgets.dart';

import 'app_frame_stub.dart' if (dart.library.js_interop) 'app_frame_web.dart'
    as platform;

/// Una app web de verdad dentro de la diapositiva (un iframe). Fuera del
/// navegador, en los tests y en las miniaturas, [placeholder].
///
/// Las teclas del control remoto (PgUp y PgDn) que lleguen a la app pasan a
/// la charla: con la app en foco, el clicker sigue pasando diapositivas.
class AppFrame extends StatelessWidget {
  const AppFrame({
    required this.path,
    required this.placeholder,
    required this.onNext,
    required this.onPrevious,
    super.key,
  });

  /// Desde la raíz del servidor: `/ecoeats/`.
  final String path;
  final Widget placeholder;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) => platform.buildFrame(
    path: path,
    placeholder: placeholder,
    onNext: onNext,
    onPrevious: onPrevious,
  );
}
