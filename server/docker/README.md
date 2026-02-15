# Docker - Backend MedRush

## Almacenamiento (imágenes, firmas, archivos)

El entrypoint crea automáticamente estos directorios si no existen:

- `storage/app/private_uploads` – avatares, fotos de entrega, firmas digitales, fotos de licencia/seguro
- `storage/app/private` – disco local privado
- `storage/temp` – archivos temporales

## Persistencia en VPS

Para que las imágenes y archivos **persistan** al reiniciar el contenedor o al redesplegar, monta un volumen en el host:

```bash
docker run -d \
  -v /ruta/en/vps/medrush-storage:/var/www/html/storage \
  ... otras opciones ...
  medrush-backend
```

O en `docker-compose`:

```yaml
services:
  backend:
    image: medrush-backend
    volumes:
      - ./medrush-storage:/var/www/html/storage
```

Así el VPS guarda todo en ese directorio y el contenedor solo lee/escribe ahí.

## Procesamiento de imágenes

- Se usa **GD** (con WebP) para redimensionar y guardar avatares/fotos en `.webp`.
- Si en el futuro se añade Imagick al Dockerfile, el código usará Imagick primero y GD como respaldo.
