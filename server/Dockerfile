# Backend Laravel - MedRush API (Produccion)
# En VPS: montar volumen persistente para imagenes/archivos/firmas, ej.:
#   -v /ruta/en/vps/medrush-storage:/var/www/html/storage
FROM php:8.2-fpm AS base

# System deps + PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    nginx \
    supervisor \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libwebp-dev \
    libonig-dev \
    libxml2-dev \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install pdo_mysql mbstring xml zip bcmath gd opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# PHP produccion config
RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY docker/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY docker/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Nginx config
COPY docker/nginx.conf /etc/nginx/sites-available/default

# Supervisor config
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

WORKDIR /var/www/html

# Dependencies (cacheadas por layer)
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY . .

# Autoload + permisos + directorios framework
RUN composer dump-autoload --optimize \
    && (php artisan config:clear || true) \
    && mkdir -p storage/framework/{cache,sessions,views} \
    && mkdir -p storage/logs \
    && mkdir -p storage/app/private_uploads storage/app/private storage/temp \
    && mkdir -p bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Entrypoint
COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/entrypoint-worker.sh /entrypoint-worker.sh
RUN chmod +x /entrypoint.sh /entrypoint-worker.sh

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/up || exit 1

ENTRYPOINT ["/entrypoint.sh"]
