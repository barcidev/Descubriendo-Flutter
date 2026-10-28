/// El widget que le toca a cada persona al entrar, con su frase.
class Persona {
  const Persona(this.widget, this.frase);

  final String widget;
  final String frase;

  Map<String, Object?> toJson() => {'widget': widget, 'frase': frase};
}

const personas = [
  Persona('Expanded', 'Ocupas todo el espacio disponible.'),
  Persona('Padding', 'Siempre guardas tu distancia.'),
  Persona('Spacer', 'Empujas a los demás para que respiren.'),
  Persona('Stack', 'Te gusta poner unas cosas encima de otras.'),
  Persona('Center', 'Siempre en el medio de todo.'),
  Persona('Hero', 'Vuelas de una pantalla a otra.'),
  Persona('FutureBuilder', 'Todavía estás cargando.'),
  Persona('StreamBuilder', 'Nunca dejas de escuchar.'),
  Persona('SafeArea', 'Esquivas el notch como nadie.'),
  Persona('Opacity', 'A veces no se te ve, pero estás.'),
  Persona('GestureDetector', 'Sientes cada toque.'),
  Persona('AnimatedContainer', 'Cambias, pero con estilo.'),
  Persona('Card', 'Elegante y con sombrita.'),
  Persona('Wrap', 'Si no cabes, saltas de línea.'),
  Persona('Flexible', 'Te adaptas a lo que haya.'),
  Persona('ListView', 'Tienes mucho que contar.'),
  Persona('InheritedWidget', 'Todos tus hijos heredan algo de ti.'),
  Persona('Scaffold', 'Sostienes todo lo demás.'),
  Persona('AspectRatio', 'Nunca pierdes las proporciones.'),
  Persona('ClipRRect', 'Le redondeas las esquinas a todo.'),
  Persona('Tooltip', 'Das pistas cuando te las piden.'),
  Persona('RepaintBoundary', 'Si cambias, no arrastras a nadie.'),
  Persona('SingleChildScrollView', 'Arreglas los overflows ajenos.'),
  Persona('SnackBar', 'Apareces un momento y te vas.'),
  Persona('CircularProgressIndicator', 'Das vueltas, pero avanzas.'),
  Persona('Dismissible', 'Un swipe y desapareces.'),
  Persona('Text', 'Directo al grano.'),
  Persona('Placeholder', 'Aquí va algo importante. Pronto.'),
  Persona('SizedBox', 'Sabes exactamente cuánto espacio ocupar.'),
  Persona('Row', 'Te gusta estar en fila con tu gente.'),
];
