FROM php:8.2-fpm-bookworm

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN apt-get update && apt-get install -y \
  libpng-dev libpq-dev libzip-dev zip unzip git curl \
  libmagickwand-dev --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

RUN usermod -u ${USER_ID} www-data && groupmod -g ${GROUP_ID} www-data
RUN docker-php-ext-install pdo_pgsql pgsql zip gd bcmath intl pcntl
RUN pecl install imagick && docker-php-ext-enable imagick

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN mkdir -p /var/www/laravel-app && chown www-data:www-data /var/www/laravel-app
WORKDIR /var/www/laravel-app

USER www-data

COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY --chown=www-data:www-data . .

RUN composer dump-autoload --optimize

EXPOSE 9000
