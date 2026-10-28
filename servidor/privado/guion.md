# Guion · Descubriendo Flutter

Tiempo total: 45 minutos. Cada sección es un comando de Flutter.
Teclas: → siguiente · ← anterior · Q QR gigante · X rayos X · T tema · S público de ensayo · 1–9 mano alzada · B pausa · O vista general · G ir a · L cerrar sesión.

## doctor · Antes de empezar, un chequeo · mientras la gente llega
- Déjala proyectada mientras entran. La terminal hace el «flutter doctor» de la sala.
- Repite en voz alta: «escaneen el QR, un solo escaneo sirve para toda la charla».
- Si alguien no puede escanear: oprime Q (QR gigante) o lee la dirección.
- Al entrar, a cada persona le toca un widget como identidad. Pregúntale a alguien cuál le tocó.

## calentamiento · ¿Con qué haces software hoy? · antes de empezar
- Votación abierta: dales 30 segundos.
- Comenta el resultado: si gana Backend Java/Kotlin, di que hoy vas a comparar mucho con Kotlin.
- Sin servidor: pide manos y suma con las teclas 1–7.

## arranque · Arranque · 2 min (sección)
- La terminal escribe sola «flutter run». Deja que termine, no la interrumpas.
- Preséntate: Jorge Palacio, Senior Frontend Developer.
- Agradece a BAQ JUG, la Universidad Autónoma del Caribe, DevJVM, Gniem, CaribeDev e IEEE Computer Society.
- Chiste de entrada: «o cómo dejar de decir “funciona en mi máquina”».

## agenda · La agenda (con overflow)
- Paso 1: «La agenda de hoy es un widget… y como todo primer intento, se desborda».
- Señala la franja amarilla y negra: «¿quién ya la conoce?». Los que levanten la mano ya usaron Flutter.
- Paso 2: el código se envuelve en SingleChildScrollView. «Así se arregla un overflow, de paso».

## una-frase · Flutter en una frase · 5 min (sección)
- Lee la frase despacio: SDK de código abierto, de Google, un solo código.
- Paso 2: la frase en palabras sencillas: «funciona en mi máquina… y en todas las demás».

## motor-de-videojuegos · Un motor de videojuegos
- Paso 1, nativo: dos códigos, dos equipos.
- Paso 2, React Native: un código, pero le pide los componentes a cada sistema.
- Paso 3, Flutter: trae su propio motor (Impeller) y pinta cada píxel, como un videojuego.
- Para no técnicos: «Flutter no usa los botones del celular: los dibuja».

## capas · Las capas · saltable
- Framework en Dart (lo que tú usas), motor en C++ (lo que pinta), embedder por plataforma.
- Si vas tarde, sáltala.

## linea-de-tiempo · Línea de tiempo · saltable
- 2015: Sky, Dart en Android apuntándole a 120 fps. 2018: 1.0. 2021: web. 2022: escritorio.
- 2026: la 3.47 separa Material y Cupertino en paquetes (material_ui, cupertino_ui).
- Si vas tarde, sáltala.

## hecha-con-flutter · ¿Hecha con Flutter?
- Paso 1: votación de selección múltiple, 40 segundos. «Sin googlear».
- Paso 2: se voltean las tarjetas. Google Pay, Nubank, My BMW y NotebookLM sí; WhatsApp, Uber e Instagram no.
- Paso 3: la trampa. «Esta presentación es una app de Flutter corriendo en Chrome».
- Oprime X: rayos X sobre el árbol real de widgets. Ciérralos con X otra vez.

## devices · flutter devices · 3 min (sección)
- Un código para celular, web y escritorio.
- Paso 2: Windows, Linux, televisores, tableros de carro, kioscos, juegos 2D con Flame.
- Chiste: «¿tu nevera? Todavía no. Aunque Whirlpool ya usa Flutter en sus apps».

## donde-vive · Dónde vive Flutter
- Todo es del showcase oficial: bancos (Nubank), Google, carros (Toyota, BMW), LG webOS, Ubuntu.
- Para la gente de la JVM: Nubank tiene una cultura fuerte de Clojure y aun así usa Flutter en el celular.

## si-depende-no · ¿Sí, depende o no? · 5 min (sección)
- Seis escenarios. Cada uno: un clic abre la votación (20 s) y otro revela la respuesta.
- Startup iOS + Android: sí. Marca propia: sí. Blog/SEO: no. Juego 3D: no (Flame para 2D sí).
- Lo último de iOS el primer día: depende. Carro/TV: sí (Toyota, LG).
- Si vas tarde, haz solo 3 escenarios y salta con G.

## issues-found · 3 issues found
- El resumen honesto como salida de «flutter analyze».
- Paso 2, dato honesto: la página de su celular NO es Flutter; para tres botones, HTML es mejor.

## pregunta-incomoda · La pregunta incómoda · saltable
- Votación: «¿Google va a matar a Flutter?». Ríete con la opción de Google Reader.
- Paso 2: Google la usa en sus apps, es código abierto (BSD), Canonical/Toyota/LG construyen encima, versión estable cada trimestre, 81.705 paquetes.

## todo-es-un-widget · Todo es un widget · 8 min (sección)
- Árbol a la izquierda, tarjeta real a la derecha.
- «Hasta el espacio entre cosas es un widget: Padding».

## armemos-una-tarjeta · Armemos una tarjeta
- Cinco pasos: Text, Column, Card con Padding, Row con ícono, FilledButton.
- Mira cómo las líneas se deslizan: cada paso envuelve al anterior.
- En el último paso dale clic a «Otra excusa» en la vista previa: es real.
- Chiste: «la firma de todo dev de Flutter: ),),),». Tip: closing labels del editor.

## ui-estado · UI = f(estado)
- No le dices a la pantalla qué cambiar: cambias el estado y Flutter reconstruye.
- Paso 2: el mismo contador en Jetpack Compose. Para la gente de Kotlin es casi idéntico.

## excusometro-en-vivo · Excusómetro en vivo
- Pide que manden su mejor excusa de dev desde el celular.
- Apruébalas en esta página (abajo, «Excusas por revisar»). Al aprobar, la tarjeta cambia en pantalla.
- Mensaje: llega un dato, cambia el estado, Flutter repinta. Nadie tocó la tarjeta.

## contador · El contador más grande del mundo
- «Aprieten el + en el celular, todo lo que puedan».
- Es el contador de flutter create, pero lo aprietan ellos.

## hot-reload · Hot reload en vivo
- Pide que sigan apretando. Cambia a VS Code y al simulador con la app contador (ver PREPARACION).
- En contador/lib/main.dart: seedColor de Colors.deepPurple a Color(0xFF027DFD) y el título por la mejor excusa. Guarda.
- Señala: cambió en menos de un segundo y el número NO volvió a cero.
- Vuelve a Chrome: paso 2 muestra el código del antes y el después.

## por-que-tan-rapido · ¿Por qué tan rápido?
- JIT mientras programas (hot reload), AOT en producción (código máquina), JS o Wasm en web.

## dart-en-60 · Dart en 60 segundos · 5 min (sección)
- Cuatro pasos: clases y tipos, async/await, null safety, records y colecciones.
- Compara con Kotlin en cada paso: final ≈ val, Future ≈ suspend.

## cual-es-dart · ¿Cuál es Dart?
- Votación A–D, 20 segundos. Es la B.
- Remate: «el resultado en los cuatro es []: ninguna excusa es creíble».

## pantalla-roja · La pantalla roja
- Paso 1: aparece la pantalla roja de error. Haz cara de pánico dos segundos.
- Paso 2: «Tranquilos, era parte del show». Explica ?. ?? y ! («confía en mí»).
- Cita de Tony Hoare: la referencia nula, el error de mil millones de dólares.

## dart-y-kotlin · Dart para quien sabe Kotlin
- Recorre la tabla rápido: val/final, nulos, data class, suspend/Future, Flow/Stream, sealed + when/switch, extensiones.

## flutter-y-sus-primos · Flutter y sus primos
- React, SwiftUI, Compose y Flutter llegaron a la misma idea: UI declarativa.

## misma-tarjeta · La misma tarjeta, cuatro veces
- Cuatro clics: Flutter, Compose, SwiftUI y React. Señala lo parecidos que son Compose y Flutter.

## crear-proyecto · Pasos 1 y 2 · 6 min (sección)
- flutter doctor y flutter create. pubspec.yaml es como build.gradle.kts.

## estructura · Paso 3: la estructura
- Carpetas por funcionalidad. Mapeo con Spring: data ≈ repository, application ≈ service, presentation ≈ controller.

## estado · Paso 4: el estado
- setState alcanza para una pantalla; para una app, un gestor (Riverpod, Bloc…). Elige uno.

## api-kotlin · Paso 5: hablar con una API en Kotlin
- Paso 1: el controlador en Kotlin (Spring Boot). Paso 2: el contrato JSON.
- Paso 3: el cliente en Dart con http y fromJson.
- Paso 4: petición real a /excusas del servidor de la charla. Muestra el tiempo en ms y las excusas que mandaron.

## errores-tipados · Cuando la API falla
- 401, 429, sin red: cada uno es un caso. sealed + switch en Dart, sealed + when en Kotlin.

## navegacion-paquetes · Pasos 6 y 7
- go_router en pocas líneas. Cómo elegir un paquete en pub.dev: likes, pub points (de 160), publicador verificado.

## tests · Paso 8: tests
- testWidgets corre la UI sin celular. Chiste: «Fue culpa mía: findsNothing, nunca pasa».

## publicar · Paso 9: publicar y el tema
- Un comando por tienda.
- Votación «¿claro u oscuro?». Paso 2: la charla aplica sola el tema ganador.

## recomendaciones · Recomendaciones · 3 min (sección)
- #0: «¿ya probaste flutter clean?».
- Tres clics: antes de empezar, mientras construyes, antes de publicar.

## por-donde-empezar · Por dónde empezar
- DartPad, el codelab oficial, Widget of the Week, pub.dev.
- Invita a la comunidad local: BAQ JUG, CaribeDev, DevJVM.

## demo · La demo · 3 min (sección)
- Paso 2 muestra los números de EcoEats: 3 días, 213 commits, 96 widgets, 407 tests.
- Cambia al simulador iPhone 16e, donde EcoEats ya tiene la sesión iniciada. Recorre: catálogo, búsqueda sin tildes («camaron»), detalle, modo Descubrir, tema e idioma.
- Para mostrar el login con JWT contra la API en Kotlin, cierra sesión desde el perfil y vuelve a entrar.
- Plan B: si el simulador falla, cuéntalo con esta diapositiva y los números de la app.

## preguntas · Preguntas · 4 min (sección)
- Pide que escriban y apoyen preguntas en el celular.
- Aprueba las buenas aquí abajo; márcalas «Respondida» al contestarlas.

## calificacion · La calificación · 1 min (sección)
- «Califiquen el deploy»: de «Segmentation fault» a «Deploy un viernes y nada se rompió».

## application-finished · Application finished.
- Gracias, contacto y agradecimiento a los organizadores.
- Deja esta diapositiva mientras sales.
