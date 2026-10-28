# Descubriendo Flutter

Charla **«Descubriendo Flutter: Creando experiencias móviles multiplataforma»**, de Jorge Palacio (Senior Frontend Developer).
28 de octubre de 2026, Universidad Autónoma del Caribe, Barranquilla. La organizan BAQ JUG, DevJVM, Gniem, CaribeDev e IEEE Computer Society UAC.

La presentación también es una app de Flutter: 37 diapositivas en Flutter Web con votaciones en vivo desde el celular, excusas y preguntas elegidas por una IA, rayos X sobre el árbol de widgets, hot reload en vivo, la app de la demo corriendo dentro de una diapositiva, créditos de película, un concurso tipo Kahoot al final y un toque de humor de desarrollador.

## Qué hay aquí

| Carpeta | Qué es |
|---|---|
| `deck/` | La presentación (Flutter Web). Lienzo de 1920×1080, navegación con teclado o control remoto, transiciones, vista general y rayos X. |
| `servidor/` | Servidor en Dart (shelf + WebSocket) para las votaciones. Incluye la página del celular, la de moderación y el guion. |
| `contador/` | La plantilla de `flutter create` con unas líneas más: el contador lo aprieta el público. Es para la demo de hot reload. |
| `servidor/ecoeats_web/` | EcoEats compilada para web: la demo que corre dentro de la charla (ver `servidor/tool/empaquetar_ecoeats.sh`). |
| `Dockerfile`, `render.yaml` | Despliegue del servidor en Render. |
| `PREPARACION.md` | Guía del día: despliegue, ensayo, checklist y plan B. |
| `GUION.md` | Copia para imprimir de las notas de cada diapositiva. |
| `FUENTES.md` | De dónde sale cada dato de la charla. |

La app de la demo final, EcoEats (Flutter con una API en Kotlin), vive en su propio repositorio.

## Cómo funciona en vivo

1. El público escanea el QR y escribe su nombre. Le toca un widget como apodo («Tu apodo de hoy: `Expanded()`»), con un ícono ⓘ que explica qué hace ese widget, y su llegada aparece en la terminal de la primera diapositiva. Los apodos no se repiten: 181 entre widgets y constructores con nombre (`ListView.builder`…) y, si llega más gente, `SizedBox(height: N)`. Si el servidor se reinicia, cada celular recupera el suyo.
2. Cada diapositiva le dice al servidor qué mostrar en los celulares: una votación, el contador, la ronda de excusas (un minuto, con cuenta regresiva), las preguntas, los créditos, el concurso o la calificación.
3. Las excusas y las preguntas las escoge Gemini en el servidor: las excusas más populares, graciosas y raras; cinco preguntas que cubran las dudas sin repetirse, sin editarlas. Si la IA falla o nadie escribe, hay plan B (con excusas de respaldo, costeñas).
4. Los resultados vuelven a la presentación en tiempo real. `GET /excusas` responde las excusas elegidas: es el contrato real de la diapositiva de la API.
5. Al final, un concurso tipo Kahoot: 10 preguntas sobre la charla, 30 segundos cada una. Acertar da de 1000 puntos (al instante) a 500 (en el último segundo); fallar, 0. Después de cada pregunta, la tabla de posiciones animada; al final, el podio de los tres primeros. Arranca con «Comenzar», en la charla o en `/moderar/`.
6. Sin internet, la charla sigue funcionando: las votaciones pasan a mano alzada con las teclas 1–9 y las rondas usan el plan B.

**Modo presentador.** Solo quien tiene el token maneja los celulares.
- **Login:** la presentación y la página `/moderar/` lo piden en una pantalla de login. Viaja dentro del WebSocket cifrado, nunca en la URL.
- **Sesión:** el servidor responde con una sesión firmada (HMAC) que vence a las 18 horas.
- **Bloqueo:** 5 intentos fallidos desde la misma IP bloquean un minuto.
- **Sin token configurado** (`PRESENTER_TOKEN`), nadie entra como presentador.
- **Lo que escribe el público** (excusas y preguntas) no aparece en pantalla sin aprobación desde `/moderar/`.

## Correr en local

Necesitas Flutter 3.47.8 (fijado con [fvm](https://fvm.app), ver `deck/.fvmrc`).

```sh
# Servidor de votaciones: http://localhost:8080 (público), /moderar/ y /deck/
cd servidor
PRESENTER_TOKEN=ensayo fvm dart run bin/server.dart

# La presentación, con hot reload
cd deck
fvm flutter run -d chrome

# O el build de producción, conectado al servidor. presentar.sh levanta un
# servidor local (charla, EcoEats web y su API) en http://127.0.0.1:8090
cd deck && fvm flutter build web --release --no-web-resources-cdn && cd ..
./presentar.sh http://localhost:8080

# Público de mentira para ensayar
cd servidor
fvm dart run tool/simular_audiencia.dart --clientes 80
```

Si `servidor/deck_web/` existe, el servidor también sirve la presentación en `/deck/` y se conecta sola a su propio origen. Para generarla: `servidor/tool/empaquetar_deck.sh`.

## Desplegar

En Render, como servicio web gratuito en Docker. `render.yaml` sirve como Blueprint. Con la CLI:

```sh
render services create --name flutter-baq --type web_service \
  --repo https://github.com/barcidev/Descubriendo-Flutter --branch main \
  --runtime docker --plan free --region virginia --health-check-path /health
```

Después agrega `PRESENTER_TOKEN` y `GEMINI_API_KEY` en Environment, en el dashboard. Los pasos completos están en `PREPARACION.md`.

Como el servicio apunta a la URL pública del repositorio, Render no se entera de los push. Después de cada cambio, despliega a mano con `render deploys create <id-del-servicio>`, o conecta GitHub en Render para que sea automático.

## Teclas

| Tecla | Acción |
|---|---|
| → ← espacio PgUp PgDn | siguiente / anterior |
| F | pantalla completa (también hay botón en la barra de estado) |
| Q | QR gigante |
| X | rayos X sobre los widgets |
| T | tema claro u oscuro |
| O | vista general |
| G + número + Enter | ir a una diapositiva |
| B | pausa (pantalla negra) |
| R | mostrar u ocultar las reacciones |
| S | público de ensayo |
| 1–9 | mano alzada (con Shift resta) |
| L | cerrar la sesión de presentador |

## Datos y privacidad

- **El servidor no guarda nada en disco ni en una base de datos.** Nombres, votos, toques, excusas, preguntas y calificaciones viven en memoria y se borran al reiniciar el servidor. En el plan gratis de Render eso pasa solo a los 15 minutos sin tráfico. Para borrarlos de inmediato: `render restart <id-del-servicio>`.
- **El nombre** solo se usa para mostrarlo en pantalla (la terminal del inicio y los créditos). Pasa por un filtro de groserías. No se piden correos ni otros datos.
- **Las excusas y las preguntas** se envían a la API de Gemini de Google para escoger las que salen en pantalla. Los nombres no se envían.
- **En los celulares** queda un identificador aleatorio, el nombre y lo que esa persona votó (`localStorage`), para que no vote dos veces.
- **En los registros del servidor** solo aparecen las conexiones del presentador y, si alguien falla 5 veces el token, la IP bloqueada. Render guarda sus propios registros de acceso según su política.

## Pruebas

```sh
cd deck && fvm flutter analyze && fvm flutter test
cd deck && fvm flutter test tool/capturas_test.dart   # un PNG por diapositiva en build/capturas/
cd servidor && fvm dart analyze && fvm dart test
```

## Créditos y licencias

- Fuentes Google Sans Flex y Google Sans Code, bajo la SIL Open Font License 1.1 (licencias en `deck/assets/fonts/`).
- La foto del presentador y los logos de quienes organizan salen de la pieza oficial de la charla.
- Logos de las apps del quiz (Google Pay, Nubank, WhatsApp, BMW, Uber, NotebookLM e Instagram): trazos de [Simple Icons](https://simpleicons.org) 16.30.0, bajo CC0. Son marcas de sus dueños y aquí solo identifican cada app.
- Flutter y el logo relacionado son marcas comerciales de Google LLC. Esta charla no está respaldada por Google LLC ni afiliada a ella. El logo se usa sin alterar, según [flutter.dev/brand](https://flutter.dev/brand).
