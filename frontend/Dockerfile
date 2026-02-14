# Stage 1: Build Flutter web
# En Dokploy: Build Args → API_BASE_URL = http://medrush-backend-xxx.traefik.me
FROM ghcr.io/cirruslabs/flutter:stable AS builder
ARG API_BASE_URL
ENV API_BASE_URL=${API_BASE_URL}
WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .
RUN if [ -n "$API_BASE_URL" ]; then \
      flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"; \
    else \
      flutter build web --release; \
    fi

# Stage 2: Serve with Nginx
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
