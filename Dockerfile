# El servidor de votaciones de la charla. Vive en servidor/, pero el
# Dockerfile va en la raíz del repositorio para que Render lo encuentre sin
# configuración extra. Compila a un ejecutable nativo sobre una imagen
# mínima: arranca rápido, que en el plan gratis importa.
FROM dart:stable AS build
WORKDIR /app
COPY servidor/pubspec.* ./
RUN dart pub get
COPY servidor/ ./
# Las copias de la charla (/deck/) y de EcoEats web (/ecoeats/) son
# opcionales: si no están, las carpetas quedan vacías.
RUN mkdir -p deck_web ecoeats_web \
 && dart pub get --offline \
 && dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server
COPY --from=build /app/public/ /app/public/
COPY --from=build /app/privado/ /app/privado/
COPY --from=build /app/deck_web/ /app/deck_web/
COPY --from=build /app/ecoeats_web/ /app/ecoeats_web/
WORKDIR /app
EXPOSE 8080
CMD ["/app/bin/server"]
