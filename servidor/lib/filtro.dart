/// Lo que escribe el público pasa por aquí antes de llegar al proyector.

/// Una línea sin caracteres de control ni espacios de más, recortada.
String? limpio(Object? valor, {required int maximo, int minimo = 3}) {
  if (valor is! String) return null;
  final texto = valor
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (texto.length < minimo) return null;
  return texto.length > maximo ? texto.substring(0, maximo).trim() : texto;
}

/// El nombre que alguien escribió al entrar, listo para la pantalla, o
/// null si no sirve (vacío, sin letras o con groserías).
String? nombreValido(Object? valor) {
  final nombre = limpio(valor, maximo: 28, minimo: 2);
  if (nombre == null || !RegExp(r'\p{L}', unicode: true).hasMatch(nombre)) {
    return null;
  }
  return esGrosero(nombre) ? null : nombre;
}

// Lo justo para un auditorio universitario: insultos y vulgaridades
// comunes en Colombia (y algunas en inglés), escritas sin tildes.
const _palabras = {
  'hp', 'hijueputa', 'hijueputas', 'hpta', 'gonorrea', 'malparido',
  'malparida', 'malparidos', 'marica', 'maricon', 'mierda', 'puta', 'puto',
  'putas', 'verga', 'vergas', 'culo', 'culos', 'culiao', 'chimba', 'pene',
  'coño', 'pendejo', 'pendeja', 'imbecil', 'idiota', 'estupido',
  'estupida', 'perra', 'zorra', 'cacorro', 'mamaguevo', 'mmgv', 'careverga',
  'carechimba', 'monda', 'fuck', 'shit', 'bitch', 'dick', 'porn', 'sexo',
  'sex', 'nazi', 'violar',
};

const _fragmentos = [
  'hijueput', 'hijodeput', 'malparid', 'gonorre', 'mamaguev', 'careverg',
  'carechimb', 'maricon', 'fuck',
];

/// Si el texto trae groserías, aunque vengan con números en vez de letras
/// o con signos en el medio.
bool esGrosero(String texto) {
  final plano = _sinTildes(texto.toLowerCase())
      .replaceAll('0', 'o')
      .replaceAll('1', 'i')
      .replaceAll('3', 'e')
      .replaceAll('4', 'a')
      .replaceAll('5', 's')
      .replaceAll('@', 'a')
      .replaceAll(r'$', 's');
  final palabras = plano
      .split(RegExp(r'[^a-zñ]+'))
      .where((palabra) => palabra.isNotEmpty);
  if (palabras.any(_palabras.contains)) return true;
  final pegado = plano.replaceAll(RegExp(r'[^a-zñ]'), '');
  return _fragmentos.any(pegado.contains);
}

/// El texto en minúsculas y sin tildes, para comparar excusas parecidas.
String normalizado(String texto) => _sinTildes(texto.toLowerCase())
    .replaceAll(RegExp(r'[^a-zñ0-9 ]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _sinTildes(String texto) {
  const de = 'áàäâéèëêíìïîóòöôúùüû';
  const a = 'aaaaeeeeiiiioooouuuu';
  final buffer = StringBuffer();
  for (final rune in texto.runes) {
    final letra = String.fromCharCode(rune);
    final i = de.indexOf(letra);
    buffer.write(i < 0 ? letra : a[i]);
  }
  return buffer.toString();
}

/// Qué tanto se parecen dos textos, de 0 a 1, por las palabras que
/// comparten (las de menos de 3 letras no cuentan).
double parecido(String a, String b) {
  Set<String> palabras(String texto) => {
        for (final palabra in normalizado(texto).split(' '))
          if (palabra.length > 2) palabra,
      };
  final x = palabras(a);
  final y = palabras(b);
  if (x.isEmpty || y.isEmpty) return 0;
  return x.intersection(y).length / x.union(y).length;
}
