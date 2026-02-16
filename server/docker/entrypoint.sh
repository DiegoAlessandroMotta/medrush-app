#!/bin/sh
set -e

# Directorios para guardar imágenes y archivos (avatars, fotos entrega, firmas, licencias, etc.)
mkdir -p storage/app/private_uploads storage/app/private storage/temp
chmod -R 775 storage/app/private_uploads storage/app/private storage/temp 2>/dev/null || true

# Si las credenciales de Route Optimization vienen por env (producción), escribirlas al archivo
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

# Función para limpiar procesos al salir
cleanup() {
  echo ">>> Shutting down..."
  if [ -n "$WORKER_PID" ]; then
    kill $WORKER_PID 2>/dev/null || true
  fi
  exit 0
}
trap cleanup SIGTERM SIGINT

# Verificar si QUEUE_CONNECTION está configurado como 'database'
QUEUE_CONNECTION=${QUEUE_CONNECTION:-sync}
echo ">>> Queue connection: $QUEUE_CONNECTION"

if [ "$QUEUE_CONNECTION" = "database" ]; then
  echo ">>> Starting Laravel queue worker in background..."
  # Desactivar set -e temporalmente para iniciar el worker
  set +e
  php artisan queue:work --queue=default --tries=2 --timeout=300 > /dev/null 2>&1 &
  WORKER_PID=$!
  set -e
  echo ">>> Queue worker started with PID: $WORKER_PID"
  sleep 2
  # Verificar que el worker sigue corriendo
  if ! kill -0 $WORKER_PID 2>/dev/null; then
    echo ">>> WARNING: Queue worker may have failed to start"
  fi
else
  echo ">>> Queue connection is '$QUEUE_CONNECTION' - worker not needed"
fi

echo ">>> Starting Laravel server..."
echo ">>> PHP version: $(php -v | head -n 1)"
echo ">>> Laravel version: $(php artisan --version)"
echo ">>> Listening on 0.0.0.0:8000"

# Verificar que Laravel puede ejecutarse
if ! php artisan --version >/dev/null 2>&1; then
  echo ">>> ERROR: Laravel artisan command failed!"
  exit 1
fi

# Iniciar el servidor
exec php artisan serve --host=0.0.0.0 --port=8000
