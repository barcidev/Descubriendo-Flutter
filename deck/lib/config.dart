/// Lo que cambia de una charla a otra. Lo del servidor también se puede
/// pasar al abrir la charla (`?servidor=…`), ver `LiveConfig`.
abstract final class Config {
  static const title = 'Descubriendo Flutter';
  static const subtitle = 'Creando experiencias móviles multiplataforma';

  static const presenter = 'Jorge Palacio';
  static const role = 'Senior Frontend Developer';

  static const venue = 'Universidad Autónoma del Caribe';
  static const city = 'Barranquilla';
  static const date = '28 de octubre de 2026 · 6:00 p. m.';

  /// Quienes organizan y apoyan, como aparecen en la pieza oficial.
  static const organizers = [
    'BAQ JUG',
    'Universidad Autónoma del Caribe',
    'DevJVM',
    'Gniem',
    'CaribeDev',
    'IEEE Computer Society UAC',
  ];

  /// Los logos para los créditos y el cierre (recortados de la pieza
  /// oficial de la charla), con su nombre.
  static const organizerLogos = [
    ('assets/creditos/baqjug.png', 'BAQ JUG'),
    ('assets/creditos/devjvm.png', 'DevJVM'),
    ('assets/creditos/gniem.png', 'Gniem'),
    ('assets/creditos/caribedev.png', 'CaribeDev'),
    ('assets/creditos/ieee.png', 'IEEE Computer Society UAC'),
  ];

  static const venueLogo = 'assets/creditos/uac.png';
  static const presenterPhoto = 'assets/creditos/jorge.png';

  /// El servidor de votaciones por defecto. Vacío: se pide en la URL.
  static const server = String.fromEnvironment('SERVIDOR');
}
