import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart' as qr;

/// Un código QR pensado para leerse desde el fondo de un auditorio:
///
/// - negro puro sobre blanco, el mayor contraste posible;
/// - la URL en mayúsculas cabe en el modo alfanumérico del QR, que gasta
///   menos bits por letra: menos módulos y por lo tanto módulos más grandes;
/// - la zona de silencio de 4 módulos que pide el estándar.
class QrCode extends StatelessWidget {
  const QrCode({required this.data, this.size = 220, super.key});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(size * 0.04),
        ),
        child: CustomPaint(painter: _QrPainter(encodeQr(data))),
      ),
    );
  }
}

final _alphanumeric = RegExp(r'^[0-9A-Z $%*+\-./:]+$');

/// El QR más pequeño posible para [data]. Si es una URL sin ruta (el
/// esquema y el dominio no distinguen mayúsculas), va en mayúsculas.
qr.QrImage encodeQr(String data) {
  final uri = Uri.tryParse(data);
  final caseless = uri != null && (uri.path.isEmpty || uri.path == '/');
  final upper = data.toUpperCase();
  final alphanumeric = caseless && _alphanumeric.hasMatch(upper);
  for (var version = 1; version <= 40; version++) {
    try {
      final code = qr.QrCode(version, qr.QrErrorCorrectLevel.M);
      if (alphanumeric) {
        code.addAlphaNumeric(upper);
      } else {
        code.addData(data);
      }
      return qr.QrImage(code);
    } on Object {
      // No cupo en esta versión: la siguiente es más grande.
    }
  }
  throw ArgumentError('Demasiado largo para un QR: $data');
}

class _QrPainter extends CustomPainter {
  const _QrPainter(this.image);

  final qr.QrImage image;

  /// Zona de silencio, en módulos.
  static const _quiet = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final count = image.moduleCount;
    final module = size.shortestSide / (count + _quiet * 2);
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..isAntiAlias = false;
    for (var row = 0; row < count; row++) {
      for (var column = 0; column < count; column++) {
        if (!image.isDark(row, column)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            (column + _quiet) * module,
            (row + _quiet) * module,
            module + 0.5,
            module + 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.image != image;
}
