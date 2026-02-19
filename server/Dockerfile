FROM dunglas/frankenphp:1-php8.2-bookworm

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN apt-get update && apt-get install -y \
  libpng-dev libpq-dev libzip-dev zip unzip git curl \
  libmagickwand-dev --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

RUN install-php-extensions pdo_pgsql pgsql zip gd bcmath intl pcntl imagick opcache

COPY Caddyfile /etc/caddy/Caddyfile

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/laravel-app

RUN set -x ; \
	useradd -u ${USER_ID} -D -S -G www-data www-data || true

ENV SERVER_NAME=:80
ENV PHP_INI_SCAN_DIR=$PHP_INI_DIR/conf.d

COPY . .

RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist \
  && composer dump-autoload --optimize

RUN chown -R www-data:www-data /var/www/laravel-app/storage /var/www/laravel-app/bootstrap/cache

RUN mkdir -p /data/caddy /config/caddy && chown -R www-data:www-data /data /config

USER www-data

EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
