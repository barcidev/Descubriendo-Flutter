#!/bin/sh
# Abre la charla desde este portátil, conectada al servidor de votaciones.
#
#   ./presentar.sh https://flutter-baq.onrender.com
#
# La charla pide el token del presentador en pantalla (nunca va en la URL).
# Sin argumentos abre en modo mano alzada (sin servidor).
#
# El servidor local sirve la charla, EcoEats web (/ecoeats/) con su API, y
# al final de los créditos trae al frente Antigravity y el simulador
# (otras apps: DEMO_APPS="App,Otra App" ./presentar.sh …).
# La primera vez en ese perfil hay que escribir el token del presentador e
# iniciar sesión en EcoEats: quedan guardados para el ensayo y la charla.
cd "$(dirname "$0")/servidor" || exit 1
fvm dart run tool/presentar.dart ../deck/build/web &
servidor_web=$!
trap 'kill $servidor_web' EXIT INT TERM
# Espera a que el servidor local conteste antes de abrir Chrome.
for _ in $(seq 1 40); do
  curl -s -o /dev/null http://127.0.0.1:8090/ && break
  sleep 0.5
done
# Chrome con un perfil solo para la charla: ventana de app en pantalla
# completa del sistema (Esc no la quita, ni la app de la demo), sin barra de
# direcciones y sin ofrecer guardar contraseñas, autocompletar ni traducir.
perfil="$HOME/.descubriendo-flutter/chrome"
mkdir -p "$perfil/Default"
if [ ! -f "$perfil/Default/Preferences" ]; then
  cat > "$perfil/Default/Preferences" <<'JSON'
{"credentials_enable_service": false, "credentials_enable_autosignin": false,
 "profile": {"password_manager_enabled": false},
 "autofill": {"enabled": false, "profile_enabled": false, "credit_card_enabled": false},
 "translate": {"enabled": false},
 "browser": {"has_seen_welcome_page": true}}
JSON
fi
open -na "Google Chrome" --args \
  --user-data-dir="$perfil" \
  --app="http://127.0.0.1:8090/?servidor=${1:-}#/1/1" \
  --start-fullscreen --no-first-run --no-default-browser-check \
  --disable-features=Translate,AutofillServerCommunication \
  --hide-crash-restore-bubble
wait $servidor_web
