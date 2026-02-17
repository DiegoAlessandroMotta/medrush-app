# Stage 1: Build Flutter web
# Producción: pasar API_BASE_URL con HTTPS si el frontend es HTTPS (evita Mixed Content).
# Ejemplo: API_BASE_URL=https://medrush-backend-xxx.traefik.me/api
#
# Build en JavaScript (no WASM): priorizamos compatibilidad 100% con Google Maps
# y mobile_scanner/cámara en web. WASM (--wasm) puede dar fallos con la cámara.
FROM ghcr.io/cirruslabs/flutter:stable AS builder
ARG API_BASE_URL
ENV API_BASE_URL=${API_BASE_URL}
WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .
# No usar --wasm: por defecto se compila a JavaScript (dart2js). Máxima compatibilidad.
# Usamos --pwa-strategy=none para desactivar el Service Worker y evitar problemas de caché (versión fantasma).
RUN if [ -n "$API_BASE_URL" ]; then \
      flutter build web --release --pwa-strategy=none --dart-define=API_BASE_URL="$API_BASE_URL"; \
    else \
      flutter build web --release --pwa-strategy=none; \
    fi

# Stage 2: Serve with Nginx
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
