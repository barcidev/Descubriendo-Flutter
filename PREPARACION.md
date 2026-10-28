# Descubriendo Flutter · preparación

Charla del 28 de octubre de 2026, 6:00 p. m., Universidad Autónoma del Caribe.

| Carpeta | Qué es |
|---|---|
| `deck/` | La presentación: una app de Flutter Web (41 diapositivas). |
| `servidor/` | Las votaciones en vivo: servidor en Dart (shelf + WebSocket), la página del celular, la página de moderación y el guion. |
| `contador/` | La plantilla de `flutter create` con 10 líneas más: escucha los toques del público. Es para el hot reload en vivo. |
| `GUION.md` | Copia para imprimir de las notas de cada diapositiva. La fuente es `servidor/privado/guion.md`, que solo se entrega a quien entra con el token. |
| `FUENTES.md` | De dónde sale cada dato de la charla. |

## 1. Un solo repositorio con todo

`deck/`, `servidor/` y `contador/` van juntos en un repositorio (EcoEats sigue en el suyo). La charla y el servidor hablan el mismo protocolo, así que cambian juntos. Render solo compila `servidor/` y el `Dockerfile` de la raíz: cambiar diapositivas no dispara despliegues.

Antes del commit, corre `servidor/tool/empaquetar_deck.sh`. Así el servidor también sirve la charla en `/deck/` como respaldo, por si el portátil falla.

```sh
cd "Presentacion"
git init && git add . && git commit -m "Charla Descubriendo Flutter"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/descubriendo-flutter.git
git push -u origin main
```

Si el repositorio es privado, Render necesita acceso a él. En el dashboard, conecta GitHub con la app de Render y dale acceso al repositorio.

## 2. Desplegar en Render (plan gratis)

Con la CLI (`render login` ya hecho):

```sh
render workspace set tea-dbgq713bc2fs73bco4pg   # My Workspace
render services create --name flutter-baq --type web_service \
  --repo https://github.com/TU_USUARIO/descubriendo-flutter --branch main \
  --runtime docker --plan free --region virginia --health-check-path /health \
  --env-var PRESENTER_TOKEN=TU_TOKEN --output json   # o sin esta línea, y lo pones en el dashboard
```

Otra opción es el dashboard: **New → Blueprint**, eliges el repositorio y Render lee `render.yaml` (`render blueprints validate render.yaml` ya lo da por válido). Ahí te pide el `PRESENTER_TOKEN`.

1. Espera el primer build, de 3 a 5 minutos (`render logs` para seguirlo).
2. La URL queda como `https://flutter-baq.onrender.com`. Si ese nombre está ocupado, Render le agrega un sufijo.
3. Comprueba que `/health` responda `ok`.

El plan gratis se duerme a los 15 minutos sin tráfico y tarda alrededor de un minuto en despertar. Durante la charla no se duerme: la presentación le manda un latido cada 20 segundos.

## 3. Abrir la charla

Opción recomendada, desde el portátil (las diapositivas funcionan aunque se caiga internet):

```sh
./presentar.sh https://flutter-baq.onrender.com
```

Respaldo, desde cualquier computador: `https://flutter-baq.onrender.com/deck/`.

**Login del presentador.** La charla abre en la pantalla «Modo presentador» y pide el token una sola vez:
- El token viaja dentro del WebSocket cifrado, nunca en la URL.
- El servidor responde con una sesión firmada que vence a las 18 horas. Al recargar, la charla entra sola con esa sesión.
- 5 intentos fallidos desde la misma IP bloquean un minuto.
- Si cambias el token en Render, todas las sesiones dejan de valer.
- «Presentar sin servidor» deja la charla en mano alzada.
- La tecla **L** cierra la sesión en ese navegador.

En el celular del presentador abre `https://flutter-baq.onrender.com/moderar/`, escribe el mismo token y tienes:
- el guion de la diapositiva actual, que solo se entrega después de entrar;
- los botones Anterior y Siguiente, que sirven de control remoto;
- la moderación de excusas y preguntas.

Nada de lo que escribe el público sale en pantalla sin que lo apruebes.

## 4. Ensayar sin público

```sh
cd servidor && PRESENTER_TOKEN=ensayo fvm dart run bin/server.dart   # http://localhost:8080
fvm dart run tool/simular_audiencia.dart --clientes 80           # en otra terminal
```

Abre `http://localhost:8080/deck/` y `http://localhost:8080/moderar/`, y entra con el token `ensayo`. Sin `PRESENTER_TOKEN`, el servidor no deja entrar a nadie como presentador.

Sin servidor también se ensaya: la tecla **S** activa un público de ensayo local.

## 5. Hot reload en vivo (diapositiva 20)

Antes de la charla, deja la app corriendo en el simulador:

```sh
cd contador
fvm flutter run -d "iPhone 17 Pro" --dart-define=SERVIDOR=wss://flutter-baq.onrender.com/ws
```

En vivo, en `contador/lib/main.dart`:
1. Cambia `Colors.deepPurple` por `Color(0xFF027DFD)`.
2. Cambia `'Flutter Demo Home Page'` por la mejor excusa.
3. Guarda. El color cambia y el número no vuelve a cero.

## 6. La demo de EcoEats (diapositiva 38)

EcoEats ya está en el simulador iPhone 16e con la sesión iniciada: no lo cierres. Corre la app `contador` en otro simulador (iPhone 17 Pro), así las dos quedan listas en ventanas separadas.

## Checklist del día

- **T−60 min:** carga el portátil. Prueba HDMI y que la resolución sea 1920×1080. Activa No molestar.
- **T−30 min:**
  - Abre `/health` para despertar el servidor.
  - Corre `./presentar.sh …`, escribe el token antes de conectar el proyector y pon Chrome en pantalla completa (tecla **F**).
  - Abre `/moderar/` en el celular y entra con el mismo token.
  - Deja corriendo `contador` en el simulador y EcoEats en el emulador.
- **T−15 min:** deja la diapositiva 1 (el doctor y el QR) mientras la gente entra. Escanea tú primero para probar.
- **Plan B sin internet:** la charla sigue. Las votaciones pasan a mano alzada: las teclas 1–9 suman votos.

## Teclas

| Tecla | Acción |
|---|---|
| → ← espacio PgUp PgDn | siguiente / anterior (sirve el control remoto) |
| Q | QR gigante |
| X | rayos X sobre los widgets |
| T | tema claro u oscuro |
| F | pantalla completa |
| B | pausa (pantalla negra) |
| O | vista general |
| G + número + Enter | ir a una diapositiva |
| R | ocultar o mostrar las reacciones |
| L | cerrar la sesión de presentador en este navegador |
| S | público de ensayo |
| 1–9 | mano alzada (con Shift resta) |
