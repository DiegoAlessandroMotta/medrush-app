# MedRushApp - Servidor Laravel

Este es el componente backend de MedRushApp desarrollado con Laravel.

## Requisitos Previos

- PHP >= 8.0
- Composer
- MySQL o PostgreSQL
- Node.js y NPM (para compilar assets)

## Instalación

1. Clonar el repositorio:
```bash
git clone https://github.com/rasoky2/MedRushApp.git
cd MedRushApp/server
```

2. Instalar dependencias de PHP:
```bash
composer install
```

3. Instalar dependencias de Node.js:
```bash
npm install
```

4. Configurar el entorno:
```bash
cp .env.example .env
php artisan key:generate
```

5. Configurar la base de datos:
   - Abrir el archivo `.env`
   - Modificar las siguientes variables con tus credenciales de base de datos:
     ```
     DB_CONNECTION=pgsql
     DB_HOST=127.0.0.1
     DB_PORT=5432
     DB_DATABASE=medrush
     DB_USERNAME=tu_usuario
     DB_PASSWORD=tu_contraseña
     ```

6. Ejecutar las migraciones:
```bash
php artisan migrate
```

7. (Opcional) Ejecutar los seeders si están disponibles:
```bash
php artisan db:seed
```

## Ejecutar el Servidor

Para iniciar el servidor de desarrollo:

```bash
composer dev
```

El servidor estará disponible en `http://localhost:4000` por defecto

Para compilar los assets en modo desarrollo:

```bash
npm run dev
```

Para compilar los assets en modo producción:

```bash
npm run build
```

## Pruebas

Para ejecutar las pruebas:

```bash
php artisan test
```

## Estructura del Proyecto

- `app/` - Contiene los modelos, controladores y lógica principal
- `config/` - Archivos de configuración
- `database/` - Migraciones y seeders
- `routes/` - Definición de rutas
- `resources/` - Vistas, assets y archivos frontend
- `tests/` - Pruebas automatizadas

## Comandos Útiles

- `php artisan route:list` - Listar todas las rutas disponibles
- `php artisan cache:clear` - Limpiar el caché
- `php artisan config:clear` - Limpiar el caché de configuración
- `php artisan migrate:fresh` - Recrear la base de datos desde cero
