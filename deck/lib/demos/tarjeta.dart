// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:material_ui/material_ui.dart';

// El código de «Armemos una tarjeta», tal cual sale en pantalla: la vista
// previa de la diapositiva corre estas funciones. Un test revisa que cada
// paso que se muestra esté escrito aquí, letra por letra. Sin `const`, para
// que el código se lea sin ruido.

Widget paso1() => Text('Funciona en mi máquina.');

Widget paso2() => Column(
  children: [
    Text('Funciona en mi máquina.'),
    Text('— Todo dev, alguna vez'),
  ],
);

Widget paso3() => Card(
  child: Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text('Funciona en mi máquina.'),
        Text('— Todo dev, alguna vez'),
      ],
    ),
  ),
);

Widget paso4() => Card(
  child: Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(spacing: 8, children: [Icon(Icons.bug_report), Text('Excusómetro')]),
        Text('Funciona en mi máquina.'),
        Text('— Todo dev, alguna vez'),
      ],
    ),
  ),
);

Widget paso5(String excusa, VoidCallback otraExcusa) => Card(
  child: Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(spacing: 8, children: [Icon(Icons.bug_report), Text('Excusómetro')]),
        Text(excusa, style: TextStyle(fontSize: 28)),
        Text('— Todo dev, alguna vez'),
        FilledButton(onPressed: otraExcusa, child: Text('Otra excusa')),
      ],
    ),
  ),
);
