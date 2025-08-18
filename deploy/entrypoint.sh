#!/usr/bin/env bash
set -euo pipefail

mkdir -p storage/framework/{cache,sessions,views} bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache || true
chmod -R ug+rwX storage bootstrap/cache || true

if [ ! -d "vendor" ] || [ -z "$(ls -A vendor || true)" ]; then
  composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader
fi

mkdir -p storage/database
[ -f storage/database/database.sqlite ] || touch storage/database/database.sqlite

php artisan key:generate --force --no-interaction || true
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true
php artisan storage:link || true
php artisan migrate --force || echo "[migrate] DB not ready, continuing..."

# просто стартуем supervisor (php-fpm + nginx)
exec /usr/bin/supervisord -c /etc/supervisord.conf
