#!/bin/sh
# Compila la charla para servirla desde el servidor en /deck/ (respaldo por
# si el portátil falla: se abre desde cualquier computador). No toca el
# build local de la charla.
set -e
cd "$(dirname "$0")/.."
destino="$(pwd)/deck_web"
cd ../deck
rm -rf "$destino"
fvm flutter build web --release --no-web-resources-cdn --no-wasm-dry-run \
  --base-href /deck/ --output "$destino"
echo "Listo: servidor/deck_web"
