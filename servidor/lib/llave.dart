import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'sala.dart' show Reloj;

/// El resultado de intentar entrar al modo presentador.
sealed class Acceso {
  const Acceso();
}

/// La clave coincidió: la sesión sirve para reconectar sin volver a escribirla.
class Concedido extends Acceso {
  const Concedido(this.sesion, this.expira);

  final String sesion;
  final DateTime expira;
}

/// Clave equivocada, o el servidor no tiene ninguna configurada.
class Denegado extends Acceso {
  const Denegado({required this.restantes, this.sinClave = false});

  /// Intentos que quedan antes del bloqueo.
  final int restantes;
  final bool sinClave;
}

/// Demasiados intentos fallidos desde el mismo lugar.
class Bloqueado extends Acceso {
  const Bloqueado(this.espera);

  final Duration espera;
}

class _Intentos {
  int fallos = 0;
  DateTime? hasta;
}

/// La llave del modo presentador.
///
/// La clave vive solo en la variable de entorno del servidor: nunca va en
/// una URL. Quien la escribe bien recibe una sesión firmada con HMAC (con la
/// misma clave) que vence sola. No se guarda nada en memoria: si el servidor
/// se reinicia, la sesión sigue valiendo; si se cambia la clave, todas las
/// sesiones dejan de valer.
class Llave {
  Llave(
    String? clave, {
    Reloj? reloj,
    this.duracion = const Duration(hours: 18),
    this.maximoFallos = 5,
    this.bloqueo = const Duration(minutes: 1),
  })  : _clave = clave == null || clave.isEmpty ? null : utf8.encode(clave),
        _reloj = reloj ?? DateTime.now;

  final List<int>? _clave;
  final Reloj _reloj;
  final Duration duracion;
  final int maximoFallos;
  final Duration bloqueo;
  final _intentos = <String, _Intentos>{};

  bool get configurada => _clave != null;

  /// Revisa [clave] escrita desde [origen] (la IP de quien la escribe).
  Acceso entrar(Object? clave, {required String origen}) {
    final ahora = _reloj();
    final intentos = _intentos.putIfAbsent(origen, _Intentos.new);
    if (intentos.hasta case final hasta? when hasta.isAfter(ahora)) {
      return Bloqueado(hasta.difference(ahora));
    }
    final real = _clave;
    if (real == null) return const Denegado(restantes: 0, sinClave: true);
    if (clave is String && _iguales(utf8.encode(clave), real)) {
      _intentos.remove(origen);
      final expira = ahora.add(duracion);
      return Concedido(_firmar(expira), expira);
    }
    intentos.fallos++;
    if (intentos.fallos >= maximoFallos) {
      intentos
        ..fallos = 0
        ..hasta = ahora.add(bloqueo);
      return Bloqueado(bloqueo);
    }
    return Denegado(restantes: maximoFallos - intentos.fallos);
  }

  /// Una sesión entregada antes, sin vencer y sin alterar.
  bool sesionValida(Object? sesion) {
    if (_clave == null || sesion is! String) return false;
    final partes = sesion.split('.');
    if (partes.length != 2) return false;
    final milisegundos = int.tryParse(partes.first);
    if (milisegundos == null) return false;
    final expira = DateTime.fromMillisecondsSinceEpoch(milisegundos);
    if (!expira.isAfter(_reloj())) return false;
    return _iguales(utf8.encode(_firmar(expira)), utf8.encode(sesion));
  }

  String _firmar(DateTime expira) {
    final momento = expira.millisecondsSinceEpoch;
    final firma =
        Hmac(sha256, _clave!).convert(utf8.encode('presentador:$momento'));
    return '$momento.$firma';
  }

  /// Compara en tiempo constante: se comparan los resúmenes, así que ni el
  /// largo ni el primer carácter distinto se notan en lo que tarda.
  static bool _iguales(List<int> a, List<int> b) {
    final x = sha256.convert(a).bytes;
    final y = sha256.convert(b).bytes;
    var diferencia = 0;
    for (var i = 0; i < x.length; i++) {
      diferencia |= x[i] ^ y[i];
    }
    return diferencia == 0;
  }
}
