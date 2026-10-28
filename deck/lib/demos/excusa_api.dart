import 'dart:convert';

import 'package:http/http.dart' as http;

// El cliente que muestra la diapositiva «Flutter hablando con una API en
// Kotlin», tal cual: la charla lo usa para pedir las excusas elegidas al
// servidor. Un test revisa que el código en pantalla sea este.

class Excusa {
  Excusa.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      texto = json['texto'] as String,
      apodo = json['apodo'] as String;

  final int id;
  final String texto;
  final String apodo;
}

Future<List<Excusa>> elegidas(Uri api) async {
  final res = await http.get(api.resolve('/excusas'));
  if (res.statusCode != 200) throw Exception('La API respondió ${res.statusCode}');
  final lista = jsonDecode(res.body) as List;
  return [for (final e in lista) Excusa.fromJson(e)];
}
