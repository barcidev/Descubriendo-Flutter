#!/bin/sh
# Abre la charla desde este portátil, conectada al servidor de votaciones.
#
#   ./presentar.sh https://flutter-baq.onrender.com TU_TOKEN
#
# Sin argumentos abre en modo mano alzada (sin servidor).
cd "$(dirname "$0")/deck/build/web" || exit 1
python3 -m http.server 8090 --bind 127.0.0.1 >/dev/null 2>&1 &
servidor_web=$!
trap 'kill $servidor_web' EXIT INT TERM
sleep 1
open -a "Google Chrome" "http://127.0.0.1:8090/?servidor=${1:-}&token=${2:-}#/1/1"
echo "Charla en http://127.0.0.1:8090 · Ctrl+C para cerrar"
wait $servidor_web
