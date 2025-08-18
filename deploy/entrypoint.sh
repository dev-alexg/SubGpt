#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] Environment: ${APP_ENV:-local}"

chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true
chmod -R ug+rwX /var/www/html/storage /var/www/html/bootstrap/cache || true

if [ ! -d "vendor" ] || [ -z "$(ls -A vendor || true)" ]; then
  echo "[entrypoint] Installing composer dependencies..."
  composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader
else
  echo "[entrypoint] Skipping composer install (vendor present)"
fi

php artisan key:generate --force --no-interaction || true
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true
php artisan storage:link || true

if [ -n "${DB_CONNECTION:-}" ]; then
  echo "[entrypoint] Running migrations..."
  php artisan migrate --force || echo "[entrypoint] Migrations failed or DB not ready, continuing..."
fi

export PORT="${PORT:-10000}"
echo "[entrypoint] Templating nginx site to listen on port ${PORT}"
apk add --no-cache gettext
envsubst '${PORT}' < /var/www/html/deploy/nginx-site.conf.template > /etc/nginx/http.d/default.conf

echo "[entrypoint] Starting supervisord (php-fpm + nginx)"
exec /usr/bin/supervisord -c /etc/supervisord.conf
