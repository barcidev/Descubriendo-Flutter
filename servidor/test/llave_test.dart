import 'dart:convert';

import 'package:servidor/llave.dart';
import 'package:servidor/sala.dart';
import 'package:test/test.dart';

void main() {
  var ahora = DateTime(2026, 10, 28, 17, 30);
  late Llave llave;

  setUp(() {
    ahora = DateTime(2026, 10, 28, 17, 30);
    llave = Llave('clave-de-la-charla', reloj: () => ahora);
  });

  test('con la clave correcta entrega una sesión que luego vale', () {
    final acceso = llave.entrar('clave-de-la-charla', origen: '1.1.1.1');
    expect(acceso, isA<Concedido>());
    final sesion = (acceso as Concedido).sesion;
    expect(llave.sesionValida(sesion), isTrue);
  });

  test('una clave equivocada cuenta los intentos que quedan', () {
    final acceso = llave.entrar('nop', origen: '1.1.1.1');
    expect(acceso, isA<Denegado>());
    expect((acceso as Denegado).restantes, 4);
  });

  test('cinco fallos bloquean un minuto, aunque después llegue la correcta', () {
    for (var i = 0; i < 4; i++) {
      llave.entrar('nop', origen: '1.1.1.1');
    }
    expect(llave.entrar('nop', origen: '1.1.1.1'), isA<Bloqueado>());
    expect(llave.entrar('clave-de-la-charla', origen: '1.1.1.1'), isA<Bloqueado>());
    // Otra IP no está bloqueada.
    expect(llave.entrar('clave-de-la-charla', origen: '2.2.2.2'), isA<Concedido>());
    ahora = ahora.add(const Duration(minutes: 1, seconds: 1));
    expect(llave.entrar('clave-de-la-charla', origen: '1.1.1.1'), isA<Concedido>());
  });

  test('la sesión vence sola', () {
    final sesion = (llave.entrar('clave-de-la-charla', origen: 'x') as Concedido).sesion;
    ahora = ahora.add(const Duration(hours: 19));
    expect(llave.sesionValida(sesion), isFalse);
  });

  test('una sesión alterada no vale', () {
    final sesion = (llave.entrar('clave-de-la-charla', origen: 'x') as Concedido).sesion;
    final [momento, firma] = sesion.split('.');
    // Estirar el vencimiento sin la clave rompe la firma.
    expect(llave.sesionValida('${int.parse(momento) + 1}.$firma'), isFalse);
    expect(llave.sesionValida('basura'), isFalse);
    expect(llave.sesionValida(null), isFalse);
  });

  test('cambiar la clave invalida las sesiones anteriores', () {
    final sesion = (llave.entrar('clave-de-la-charla', origen: 'x') as Concedido).sesion;
    final nueva = Llave('otra-clave', reloj: () => ahora);
    expect(nueva.sesionValida(sesion), isFalse);
  });

  test('sin clave configurada nadie entra', () {
    final sinClave = Llave(null);
    expect(sinClave.configurada, isFalse);
    final acceso = sinClave.entrar('', origen: 'x');
    expect(acceso, isA<Denegado>());
    expect((acceso as Denegado).sinClave, isTrue);
  });

  test('al entrar, la conexión pasa de público a presentador', () {
    final sala = Sala();
    final recibidos = <String>[];
    final conexion = Conexion(enviar: recibidos.add, presentador: false);
    sala
      ..entrar(conexion)
      ..recibir(conexion, jsonEncode({'t': 'cue', 'cue': {'mode': 'rating'}}));
    expect(sala.modo, 'idle', reason: 'antes de entrar no controla nada');
    sala
      ..promover(conexion)
      ..recibir(conexion, jsonEncode({'t': 'cue', 'cue': {'mode': 'rating'}}));
    expect(sala.modo, 'rating');
  });
}
