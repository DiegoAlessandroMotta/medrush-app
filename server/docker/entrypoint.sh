#!/bin/bash
set -e

# Directorios para guardar imagenes y archivos (avatars, fotos entrega, firmas, licencias, etc.)
mkdir -p storage/framework/{cache,sessions,views}
mkdir -p storage/logs bootstrap/cache
mkdir -p storage/app/private_uploads storage/app/private storage/temp
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

echo ">>> MedRush backend: waiting for database..."
max_attempts=30
attempt=0
# Fix migration date order
if [ -f database/migrations/2025_02_14_000000_drop_dni_columns_from_perfiles_repartidor_table.php ]; then
  mv database/migrations/2025_02_14_000000_drop_dni_columns_from_perfiles_repartidor_table.php database/migrations/2026_02_14_000000_drop_dni_columns_from_perfiles_repartidor_table.php
fi
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

# Verificar configuracion de cola
QUEUE_CONNECTION=${QUEUE_CONNECTION:-sync}
echo ">>> Queue connection: $QUEUE_CONNECTION"

# Funcion para limpiar procesos al salir
cleanup() {
  echo ">>> Shutting down..."
  if [ -n "$WORKER_PID" ]; then
    kill $WORKER_PID 2>/dev/null || true
  fi
  exit 0
}
trap cleanup SIGTERM SIGINT

# Solo iniciar worker si QUEUE_CONNECTION es 'database'
if [ "$QUEUE_CONNECTION" = "database" ]; then
  echo ">>> Starting Laravel queue worker in background..."
  set +e
  php artisan queue:work --queue=default --tries=2 --timeout=300 > /dev/null 2>&1 &
  WORKER_PID=$!
  set -e
  echo ">>> Queue worker started with PID: $WORKER_PID"
  sleep 1
else
  echo ">>> Using '$QUEUE_CONNECTION' queue - jobs will run synchronously"
fi

# Verificar que Laravel puede ejecutarse
echo ">>> Verifying Laravel installation..."
if ! php artisan --version >/dev/null 2>&1; then
  echo ">>> ERROR: Laravel artisan command failed!"
  exit 1
fi

echo ">>> PHP version: $(php -v | head -n 1 | cut -d' ' -f1-3)"
echo ">>> Laravel version: $(php artisan --version)"
echo ">>> Starting Laravel server on 0.0.0.0:8000..."

# Iniciar el servidor (esto debe ser el ultimo comando y usar exec)
exec php artisan serve --host=0.0.0.0 --port=8000
