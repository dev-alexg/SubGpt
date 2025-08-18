# syntax=docker/dockerfile:1.6
FROM php:8.2-fpm-alpine

RUN apk add --no-cache \
    nginx supervisor bash git curl zip unzip icu-dev \
    libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev \
    oniguruma-dev libxml2-dev \
    postgresql-dev postgresql-libs

RUN docker-php-ext-configure gd --with-jpeg --with-webp \
 && docker-php-ext-install -j$(nproc) \
    pdo pdo_mysql pdo_pgsql bcmath intl gd exif zip opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

COPY deploy/nginx.conf /etc/nginx/nginx.conf
COPY deploy/supervisord.conf /etc/supervisord.conf
COPY deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV APP_ENV=production \
    PHP_OPCACHE_ENABLE=1 \
    PHP_OPCACHE_ENABLE_CLI=1 \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
    PHP_MEMORY_LIMIT=256M \
    PORT=10000

EXPOSE 10000
CMD ["/entrypoint.sh"]
