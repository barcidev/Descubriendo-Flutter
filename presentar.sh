#!/bin/sh
# Abre la charla desde este portátil, conectada al servidor de votaciones.
#
#   ./presentar.sh https://flutter-baq.onrender.com
#
# La charla pide el token del presentador en pantalla (nunca va en la URL).
# Sin argumentos abre en modo mano alzada (sin servidor).
#
# El servidor local sirve la charla, EcoEats web (/ecoeats/) con su API, y
# al final de los créditos trae al frente el simulador (DEMO_APPS).
cd "$(dirname "$0")/servidor" || exit 1
fvm dart run tool/presentar.dart ../deck/build/web &
servidor_web=$!
trap 'kill $servidor_web' EXIT INT TERM
# Espera a que el servidor local conteste antes de abrir Chrome.
for _ in $(seq 1 40); do
  curl -s -o /dev/null http://127.0.0.1:8090/ && break
  sleep 0.5
done
open -a "Google Chrome" "http://127.0.0.1:8090/?servidor=${1:-}#/1/1"
wait $servidor_web
