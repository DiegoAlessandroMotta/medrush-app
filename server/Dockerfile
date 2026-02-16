# Backend Laravel - MedRush API
# En VPS: montar volumen persistente para imagenes/archivos/firmas, ej.:
#   -v /ruta/en/vps/medrush-storage:/var/www/html/storage
FROM php:8.2-cli

# System deps + PHP extensions (gd con WebP para avatares, fotos entrega, firmas, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    curl \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libwebp-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install pdo_mysql mbstring xml zip bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

WORKDIR /var/www/html

# Dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY . .

# Entrypoint: migrate + seed + serve (todo listo al arrancar)
COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/entrypoint-worker.sh /entrypoint-worker.sh
RUN chmod +x /entrypoint.sh /entrypoint-worker.sh

RUN composer dump-autoload --optimize \
    && (php artisan config:clear || true) \
    && mkdir -p storage/framework/{cache,sessions,views} \
    && mkdir -p storage/logs bootstrap/cache \
    && mkdir -p storage/app/private_uploads storage/app/private storage/temp \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/up || exit 1

ENTRYPOINT ["/entrypoint.sh"]
