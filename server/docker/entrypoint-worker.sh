#!/bin/bash
set -e

# Directorios para guardar imágenes y archivos
mkdir -p storage/app/private_uploads storage/app/private storage/temp
chmod -R 775 storage/app/private_uploads storage/app/private storage/temp 2>/dev/null || true

echo ">>> MedRush queue worker: waiting for database..."
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

echo ">>> Starting Laravel queue worker..."
exec php artisan queue:work --queue=default --tries=2 --timeout=300
