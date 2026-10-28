import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// El código que sale en pantalla es el que corre: si alguien cambia uno y
/// no el otro, este test falla.
void main() {
  String leer(String ruta) =>
      File(ruta).readAsStringSync().replaceAll(r'\$', r'$');

  test('cada paso de «Armemos una tarjeta» está en lib/demos/tarjeta.dart', () {
    final fuente = leer('lib/demos/tarjeta.dart');
    final diapositiva = leer('lib/slides/s05_build.dart');
    final pasos = RegExp(r'^Widget paso\d\([^)]*\) => (.*?);\n', multiLine: true, dotAll: true)
        .allMatches(fuente)
        .map((m) => m[1]!)
        .toList();
    expect(pasos, hasLength(5));
    for (final paso in pasos) {
      expect(diapositiva, contains("'''\n$paso'''"));
    }
  });

  test('el cliente de la API en pantalla es el que hace la petición', () {
    final fuente = leer('lib/demos/excusa_api.dart');
    final cliente = fuente.substring(fuente.indexOf('class Excusa {')).trimRight();
    expect(leer('lib/slides/s07_create.dart'), contains("'''\n$cliente'''"));
  });
}
