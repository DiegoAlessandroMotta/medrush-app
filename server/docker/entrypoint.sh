#!/bin/sh
set -e

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

echo ">>> Starting Laravel server..."
exec php artisan serve --host=0.0.0.0 --port=8000
