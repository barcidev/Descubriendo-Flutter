#!/bin/sh
# Compila EcoEats para web y lo deja en servidor/ecoeats_web, para la
# diapositiva de la demo (la app corre dentro de la charla) y para Render.
#
#   servidor/tool/empaquetar_ecoeats.sh [ruta/a/ecoeats]
#
# Trabaja sobre una copia: el repositorio de EcoEats no se toca. En la copia
# se agrega la plataforma web y la API apunta al mismo origen (/ecoeats-api):
# el servidor la reenvía, porque la API en Kotlin no acepta CORS.
set -e
cd "$(dirname "$0")/.."
destino="$(pwd)/ecoeats_web"
origen="${1:-../../EcoEats/ecoeats}"
copia="$(mktemp -d)/ecoeats"
trap 'rm -rf "$(dirname "$copia")"' EXIT

rsync -a --exclude build --exclude .dart_tool --exclude .git \
  --exclude ios --exclude android --exclude test "$origen/" "$copia/"
cd "$copia"
# Web solo para esta copia, como en la charla: la configuración global de
# Flutter queda igual.
perl -0pi -e 's/^flutter:\n/flutter:\n  config:\n    enable-web: true\n/m' pubspec.yaml
fvm flutter create --platforms=web --project-name ecoeats .
# flutter_native_splash quita su splash con una función de JS que solo existe
# si se genera el splash para web: aquí basta con que exista.
perl -0pi -e 's#</head>#  <script>window.removeSplashFromWeb = function () {};</script>\n</head>#' web/index.html
cat > lib/core/config/env.dart <<'DART'
import 'package:flutter/foundation.dart';

abstract final class Env {
  /// En la charla, la API se pide al mismo servidor que sirve la página: él
  /// la reenvía a la de Kotlin (que no acepta peticiones de otros orígenes).
  static final apiBaseUrl = kIsWeb
      ? Uri.base.resolve('/ecoeats-api').toString()
      : const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://ecoeats-api-kotlin-production.up.railway.app',
        );
}
DART
rm -rf "$destino"
fvm flutter build web --release --base-href /ecoeats/ --no-wasm-dry-run \
  --no-web-resources-cdn --output "$destino"
echo "Listo: servidor/ecoeats_web"
