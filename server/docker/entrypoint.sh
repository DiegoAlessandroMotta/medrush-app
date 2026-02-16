#!/bin/bash
set -e

# Directorios para guardar imagenes y archivos (avatars, fotos entrega, firmas, licencias, etc.)
mkdir -p storage/app/private_uploads storage/app/private storage/temp
mkdir -p storage/framework/{cache,sessions,views}
mkdir -p storage/logs bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true
chmod -R 775 storage bootstrap/cache 2>/dev/null || true

# Si las credenciales de Route Optimization vienen por env (produccion), escribirlas al archivo
if [ -n "$GOOGLE_ROUTE_OPTIMIZATION_CREDENTIALS_JSON" ]; then
  mkdir -p storage/services/google
  if echo "$GOOGLE_ROUTE_OPTIMIZATION_CREDENTIALS_JSON" | base64 -d > storage/services/google/service-account.json 2>/dev/null; then
    echo ">>> Google Route Optimization: credenciales inyectadas desde env (base64)."
  else
    echo "$GOOGLE_ROUTE_OPTIMIZATION_CREDENTIALS_JSON" > storage/services/google/service-account.json
    echo ">>> Google Route Optimization: credenciales inyectadas desde env (JSON)."
  fi
fi

# Limpiar cache de configuracion
php artisan config:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

echo ">>> MedRush backend: waiting for database..."
max_attempts=30
attempt=0
until php artisan migrate --force 2>/dev/null; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge "$max_attempts" ]; then
    echo ">>> Database not available after ${max_attempts} attempts. Exiting."
    exit 1
  fi
  echo ">>> Attempt $attempt/$max_attempts - waiting 2s..."
  sleep 2
done

# Seed solo la primera vez (evita duplicar admin al reiniciar)
if [ ! -f storage/.seeded ]; then
  echo ">>> Running seeders (first run)..."
  php artisan db:seed --force
  touch storage/.seeded
else
  echo ">>> Seed already applied, skipping."
fi

# Cache para produccion
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

# Storage link
php artisan storage:link 2>/dev/null || true

echo ">>> PHP version: $(php -v | head -n 1 | cut -d' ' -f1-3)"
echo ">>> Laravel version: $(php artisan --version)"
echo ">>> Starting Nginx + PHP-FPM via Supervisor..."

# Supervisor gestiona Nginx y PHP-FPM
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
