# Guion · Descubriendo Flutter

Tiempo total: 45 minutos. Cada sección es un comando de Flutter.
Las excusas y las preguntas las escoge Gemini en el servidor (GEMINI_API_KEY); sin clave, o si falla, hay plan B.
Teclas: → siguiente · ← anterior · Q QR gigante · X rayos X · T tema · S público de ensayo · 1–9 mano alzada · B pausa · O vista general · G ir a · L cerrar sesión.

## doctor · Antes de empezar, un chequeo · mientras la gente llega
- Déjala proyectada mientras entran. La terminal hace el «flutter doctor» de la sala.
- Repite en voz alta: «escaneen el QR, un solo escaneo sirve para toda la charla».
- Si alguien no puede escanear: oprime Q (QR gigante) o lee la dirección.
- Al entrar, cada persona escribe su nombre y le toca un widget: ese es su apodo. Los nombres van apareciendo en la terminal («Llegó Ana → Expanded()»).
- Pregúntale a alguien cuál le tocó. Diles que guarden el nombre para el final: salen en los créditos.
- Cada apodo es único: hay 181 (widgets y constructores con nombre como ListView.builder); si llega más gente, SizedBox(height: N). El ícono ⓘ junto al apodo explica qué hace ese widget.

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
- Paso 3: la trampa. La tarjeta de «Esta presentación» se va al centro y se voltea: «es una app de Flutter corriendo en Chrome».
- Desde aquí la barra de abajo muestra «Flutter 3.47 · Dart 3.13»: antes no había nada que lo delatara.
- Oprime X: rayos X sobre el árbol real de widgets. Ciérralos con X otra vez.

## devices · flutter devices · 3 min (sección)
- Un código para celular, web y escritorio.
- Paso 2: Windows, Linux, televisores, tableros de carro, kioscos, juegos 2D con Flame.
- Chiste: «¿tu nevera? Todavía no. Aunque Whirlpool ya usa Flutter en sus apps».

## donde-vive · Dónde vive Flutter
- Todo es del showcase oficial: bancos (Nubank), Google, carros (Toyota, BMW), LG webOS, Ubuntu.
- Para la gente de la JVM: Nubank tiene una cultura fuerte de Clojure y aun así usa Flutter en el celular.

## si-depende-no · ¿Sí, depende o no? · 5 min (sección)
- Cuatro escenarios. Cada uno: un clic abre la votación (20 s) y otro revela la respuesta.
- Startup iOS + Android: sí. Blog o tienda que vive del SEO: no.
- Lo último de iOS el mismo día: depende (código nativo y canales de plataforma). Carro o TV: sí (Toyota, LG).
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
- El código es el de verdad: la vista previa corre exactamente ese código, en una pantalla de celular ampliada.
- Mira cómo las líneas se deslizan: cada paso envuelve al anterior.
- En el último paso dale clic a «Otra excusa» en la vista previa: es real.
- Chiste: «la firma de todo dev de Flutter: ),),),». Tip: closing labels del editor.

## ui-estado · UI = f(estado)
- No le dices a la pantalla qué cambiar: cambias el estado y Flutter reconstruye.
- Paso 2: el mismo contador en Jetpack Compose. Para la gente de Kotlin es casi idéntico.

## excusometro-en-vivo · Excusómetro en vivo
- Un minuto en pantalla para mandar su mejor excusa desde el celular (hasta tres por persona). Mientras tanto gira la ruleta de la culpa.
- Si ya escribieron todos, un clic cierra antes. Si se acaba el tiempo, la charla pasa sola al paso 2.
- Paso 2: una IA (Gemini) hace «code review» y escoge las más populares, las más graciosas y la más rara. Sin categorías.
- Si la IA falla o nadie escribe, salen excusas de respaldo (costeñas) mezcladas con las reales. Nadie lo nota.
- Mensaje: llega un dato, cambia el estado, Flutter repinta. Nadie tocó las tarjetas.
- Si algo sale en pantalla que no debe, quítalo aquí abajo («Excusas en pantalla» → Quitar).
## contador · El contador más grande del mundo
- «Aprieten el + en el celular, todo lo que puedan».
- Es el contador de flutter create, pero lo aprietan ellos.

## hot-reload · Hot reload en vivo
- Pide que sigan apretando. El celular de la diapositiva es la plantilla de flutter create con su contador.
- Paso 2: cambia el color y el título en el código y el celular de la diapositiva cambia igual, sin perder el número.
- Después hazlo de verdad: VS Code y el simulador con la app contador (ver PREPARACION). seedColor a Color(0xFF027DFD) y el título por la mejor excusa. Guarda.
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

- Los celulares también «revientan» con la pantalla roja (y vibran). En el paso 2 se arreglan solos: «Tranquilo: era parte del show».
## flutter-y-sus-primos · Flutter y sus primos
- React, SwiftUI, Compose y Flutter llegaron a la misma idea: UI declarativa.

## misma-tarjeta · La misma tarjeta, cuatro veces
- Cuatro clics: Flutter, Compose, SwiftUI y React. Señala lo parecidos que son Compose y Flutter.

## crear-proyecto · Pasos 1 y 2 · 6 min (sección)
- flutter doctor y flutter create. pubspec.yaml es como build.gradle.kts.

## api-kotlin · Paso 3: hablar con una API en Kotlin
- Paso 1: el controlador en Kotlin (Spring Boot). Paso 2: el contrato JSON, el de verdad de GET /excusas, con la primera excusa que salió en pantalla.
- Paso 3: el cliente en Dart con http y fromJson. Es el código que hace la petición del paso 4.
- Paso 4: petición real a /excusas del servidor de la charla: son las mismas excusas que eligió la IA.
- Si preguntan por errores: la línea del statusCode lanza una excepción y FutureBuilder la muestra en su estado de error. Con eso basta para empezar.
## paquetes · Paso 4: paquetes
- pub.dev es a Flutter lo que Maven Central a Spring y npm a Node: mismo concepto, otro nombre de archivo.
- Lo diferente: cada paquete trae nota. Pub points (de 160, análisis automático), likes, descargas, publicador verificado y Flutter Favorite.
## publicar · Paso 5: publicar y el tema
- Un comando por tienda.
- Votación «¿claro u oscuro?». Paso 2: la charla aplica sola el tema ganador.
- Paso 3, el chiste: si ganó el claro, «git revert tema-claro» y vuelve el oscuro («democracia sí, pero esta charla es mía»). Si ganó el oscuro: «¿por qué los devs usan modo oscuro? Porque la luz atrae a los bugs».
- Si hay empate, en el paso 2 la charla parpadea entre los dos temas («no sabe qué ponerse») y en el paso 3 es un conflicto de merge: decide quien tiene permisos de admin, modo oscuro.
## recomendaciones · Recomendaciones · 3 min (sección)
- #0: «¿ya probaste flutter clean?».
- Tres clics: antes de empezar, mientras construyes, antes de publicar.
- En «un solo gestor de estado» nombra Provider, Riverpod y Bloc: el que sea, pero uno.

## por-donde-empezar · Por dónde empezar
- DartPad, el codelab oficial, Widget of the Week, pub.dev.
- Invita a la comunidad local: BAQ JUG, CaribeDev, DevJVM.
- El QR de la guía oficial está en el cierre, para escanearlo al salir.

## demo · La demo · 3 min (sección)
- La terminal «compila», el iPhone de la diapositiva arranca y abre EcoEats: es la app real, versión web, contra la API en Kotlin.
- La app se carga escondida desde que abre la charla: al llegar aquí ya está lista, sin pantalla en blanco. Si sales y vuelves, sigue donde la dejaste.
- Úsala con el mouse como si fuera un dedo: toques, arrastres y el gesto de deslizar desde el borde para volver (se comporta como en un iPhone).
- Recórrela: login con JWT, catálogo, búsqueda sin tildes («camaron»), detalle, tema e idioma.
- El clicker sigue funcionando con la app en foco (PgUp y PgDn).
- Paso 2 muestra los números de EcoEats: 3 días, 213 commits, 96 widgets, 407 tests.
- La app en el simulador del Mac va al final, después de los créditos.
## preguntas · Preguntas · 4 min (sección)
- Las preguntas llegan toda la charla. Al entrar aquí, una IA escoge cinco que cubran la mayoría de dudas, sin repetir y sin editarlas.
- La espera dura al menos 10 segundos: el FutureBuilder «esperando stdin». Aprovecha para pedir que escriban la suya.
- Sin preguntas: «stdin vacío», y pide manos.
- Si algo no debe salir, quítalo aquí abajo («Preguntas en pantalla» → Quitar).
## creditos · Los créditos · 1 min (sección)
- Pantalla completa, como en el cine: la charla en números, el elenco (el público con su nombre y su apodo), los organizadores y tu foto.
- Escena post-créditos: «¿Creyeron que todo esto eran diapositivas? Era un mock: N widgets haciéndose pasar por PowerPoint.» Un mock es lo que en los tests se hace pasar por otra cosa: eso eran las diapositivas.
- Cinco segundos después, el Mac trae al frente Antigravity y el simulador (con presentar.sh) y la charla pasa sola al concurso. Muestra la app de verdad y vuelve con Cmd+Tab.
- Sin presentar.sh, la charla sale de pantalla completa: cambia al simulador con Cmd+Tab.
## concurso · Concurso final · 5 min
- Al volver del simulador del Mac (Cmd+Tab), la charla espera aquí: las reglas y el botón «Comenzar». También lo tienes en este celular.
- 10 preguntas sobre la charla, 30 segundos cada una. Acertar da de 1000 puntos (al instante) a 500 (al final); fallar, 0. Juega quien dio su nombre.
- La pregunta se cierra sola a los 30 s o cuando todos respondieron, y la charla pasa sola a la respuesta y la tabla. Un clic adelanta el cierre.
- En la tabla, un clic abre la siguiente pregunta. Después de la décima, el podio: suben el tercero, el segundo y, con redoble, el ganador.
- Lee la pregunta en voz alta y haz barra: «¡quedan diez segundos!».

## application-finished · Application finished.
- Al volver del simulador ya está aquí: gracias, la calificación en vivo («Califiquen el deploy»), el QR de la guía oficial para empezar mañana y los organizadores.
- Deja esta diapositiva mientras sales.
