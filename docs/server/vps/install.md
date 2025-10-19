# Cómo preparar un VPS (Debian 12) para una aplicación Laravel

Esta guía detalla la instalación de los componentes necesarios en un servidor Debian 12 para hospedar una aplicación Laravel que utiliza PostgreSQL con PostGIS, Supervisor para un worker y Laravel Reverb. Se enfoca en la preparación del entorno, no en el proceso de despliegue de la aplicación en sí.

## 1. Acceso al VPS y Configuración Inicial del Usuario

1. **Acceder a tu instancia VPS:**
    Utiliza SSH para conectarte a tu servidor. La mayoría de los proveedores de VPS te proporcionarán los detalles de acceso (IP, usuario `root`, contraseña o clave SSH).

    ```bash
    ssh root@vps_ip_address
    ```

    > **Nota:** En caso de ser necesario puedes instalar `openssh-server` con el siguiente comando `sudo apt install -y openssh-server`

2. **Crear un nuevo usuario con privilegios `sudo`:**
    No es una buena práctica operar directamente como usuario `root` para tareas diarias o para la aplicación. Crea un nuevo usuario para tu aplicación y otórgale privilegios `sudo`. Usaremos `laravelapp` como nombre de usuario de ejemplo.

    ```bash
    adduser laravelapp
    ```

    Se te pedirá una contraseña para el nuevo usuario y, opcionalmente, algunos detalles adicionales que puedes dejar en blanco. Una vez creado el usuario, añádelo al grupo `sudo` para que pueda ejecutar comandos con privilegios administrativos.

    ```bash
    usermod -aG sudo laravelapp
    ```

3. **Cambiar al nuevo usuario:**
    Cierra tu sesión `root` y vuelve a conectarte como `laravelapp` o usa `su` para cambiar de usuario.

    ```bash
    exit
    ```

    Luego, conéctate de nuevo:

    ```bash
    ssh laravelapp@vps_ip_address
    ```

    O si ya estás conectado como `root`:

    ```bash
    su - laravelapp
    ```

## 2. Actualizar el Sistema

Es fundamental mantener tu sistema operativo actualizado para obtener las últimas características de seguridad y correcciones de errores.

```bash
sudo apt update
sudo apt upgrade -y
```

## 3. Instalar Nginx

Nginx es un servidor web ligero y de alto rendimiento que servirá tu aplicación Laravel.

```bash
sudo apt install nginx -y
```

Verifica que Nginx esté corriendo:

```bash
sudo systemctl status nginx
```

Si no está activo, inicia y habilita Nginx para que se inicie en el arranque:

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

## 4. Instalar PostgreSQL y PostGIS

Laravel utilizará PostgreSQL como base de datos, y para características geoespaciales, instalaremos PostGIS.

```bash
sudo apt install postgresql postgresql-contrib postgis -y
```

Verifica el estado de PostgreSQL:

```bash
sudo systemctl status postgresql
```

Si no está activo, inicia y habilita PostgreSQL:

```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Configurar Usuario y Base de Datos en PostgreSQL

1. **Acceder al prompt de PostgreSQL como el usuario `postgres`:**

    ```bash
    sudo -i -u postgres psql
    ```

2. **Crear un nuevo usuario de base de datos:**
    Este usuario es para que tu aplicación Laravel se conecte a la base de datos. Reemplaza `your_db_user` y `your_db_password` con credenciales seguras.

    ```sql
    CREATE USER your_db_user WITH PASSWORD 'your_db_password';
    ```

3. **Crear la base de datos:**
    Reemplaza `your_db_name` con el nombre de tu base de datos.

    ```sql
    CREATE DATABASE your_db_name OWNER your_db_user;
    ```

4. **Habilitar la extensión PostGIS en tu base de datos:**
    Es importante que esta extensión se habilite en la base de datos específica de tu aplicación.

    ```sql
    \c your_db_name;
    CREATE EXTENSION postgis;
    ```

5. **Otorgar todos los privilegios a la base de datos:**

    ```sql
    GRANT ALL PRIVILEGES ON DATABASE your_db_name TO your_db_user;
    ```

6. **Salir del prompt de PostgreSQL:**

    ```sql
    \q
    ```

## 5. Instalar PHP y Extensiones Necesarias

Laravel requiere PHP. Instalaremos PHP 8.2 (la versión actual recomendada al momento de escribir esto) y las extensiones comunes para Laravel.

1. **Añadir el repositorio `ondrej/php` (SURY PPA):**
    Esto nos permite obtener versiones más recientes de PHP en Debian.

    ```bash
    sudo apt install curl ca-certificates gnupg -y
    curl -sSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /usr/share/keyrings/deb.sury.org-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ bookworm main" | sudo tee /etc/apt/sources.list.d/sury-php.list
    sudo apt update
    ```

2. **Instalar PHP 8.2 y extensiones:**

    ```bash
    sudo apt install php8.2-fpm php8.2-common php8.2-cli php8.2-curl php8.2-mbstring php8.2-xml php8.2-zip php8.2-gd php8.2-pgsql php8.2-bcmath php8.2-soap php8.2-intl php8.2-readline imagemagick libmagickwand-dev php8.2-imagick -y
    ```

3. **Verificar la versión de PHP:**

    ```bash
    php -v
    ```

4. **Verificar el estado de PHP-FPM:**

    ```bash
    sudo systemctl status php8.2-fpm
    ```

    Si no está activo, inicia y habilita PHP-FPM:

    ```bash
    sudo systemctl start php8.2-fpm
    sudo systemctl enable php8.2-fpm
    ```

## 6. Instalar Composer

Composer es el gestor de dependencias para PHP, esencial para Laravel.

```bash
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer
```

Verifica la instalación:

```bash
composer -V
```

## 7. Instalar Node.js y npm (para Laravel Reverb)

Laravel Reverb requiere Node.js para su ejecución.

1. **Instalar Node.js desde los repositorios de NodeSource:**
    Esto asegura que obtengas una versión LTS reciente y estable.

    ```bash
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
    ```

2. **Verificar las versiones de Node.js y npm:**

    ```bash
    node -v
    npm -v
    ```

## 8. Instalar Supervisor

Supervisor es un sistema de monitoreo de procesos que se utiliza para asegurar que tus procesos de Laravel (como los workers de la cola o Laravel Reverb) se estén ejecutando y se reinicien automáticamente si fallan.

```bash
sudo apt install supervisor -y
```

Verifica el estado de Supervisor:

```bash
sudo systemctl status supervisor
```

Si no está activo, inicia y habilita Supervisor:

```bash
sudo systemctl start supervisor
sudo systemctl enable supervisor
```

### Configuración básica de Supervisor (para un worker y Reverb)

Crearás archivos de configuración dentro de `/etc/supervisor/conf.d/`.

1. **Crear el archivo de configuración para el worker de la cola de Laravel:**

    ```bash
    sudo nano /etc/supervisor/conf.d/laravel-worker.conf
    ```

    Pega el siguiente contenido (asegúrate de reemplazar `/var/www/laravel-app` con la ruta real de tu aplicación):

    ```ini
    [program:laravel-worker]
    process_name=%(program_name)s_%(process_num)02d
    command=php /var/www/laravel-app/artisan queue:work --timeout=600 --sleep=3 --tries=2 --max-time=1800
    directory=/var/www/laravel-app
    autostart=true
    autorestart=true
    user=www-data
    numprocs=1
    redirect_stderr=true
    stdout_logfile=/var/www/laravel-app/storage/logs/queue-worker.log
    stopwaitsecs=3600
    ```

2. **Crear el archivo de configuración para Laravel Reverb:**

    ```bash
    sudo nano /etc/supervisor/conf.d/laravel-reverb.conf
    ```

    Pega el siguiente contenido (asegúrate de reemplazar `/var/www/laravel-app` con la ruta real de tu aplicación):

    ```ini
    [program:laravel-reverb]
    command=php /var/www/laravel-app/artisan reverb:start --host=0.0.0.0 --port=9000 --debug
    directory=/var/www/laravel-app
    numprocs=1
    autostart=true
    autorestart=true
    user=www-data
    redirect_stderr=true
    stdout_logfile=/var/www/laravel-app/storage/logs/reverb.log
    stopwaitsecs=3600
    ```

3. **Cargar y actualizar las configuraciones de Supervisor:**

    ```bash
    sudo supervisorctl reread
    sudo supervisorctl update
    sudo supervisorctl status
    ```

    Verifica que `laravel-worker` y `laravel-reverb` estén en estado `RUNNING`.

## 9. Configuración del Servidor Web (Nginx)

Necesitarás configurar un "server block" en Nginx para tu aplicación Laravel.

1. **Crear y configurar el directorio para tu aplicación:**
    En este ejemplo, usaremos `/var/www/laravel-app`. Asignaremos la propiedad al usuario `laravelapp` y configuraremos permisos. También, añadiremos el usuario `www-data` (el usuario que ejecuta Nginx y PHP-FPM) al grupo `laravelapp` y viceversa para facilitar los permisos.

    ```bash
    sudo mkdir -p /var/www/laravel-app
    sudo chown -R laravelapp:laravelapp /var/www/laravel-app
    sudo chmod -R 775 /var/www/laravel-app

    sudo usermod -aG laravelapp www-data
    sudo usermod -aG www-data laravelapp
    ```

    > **Nota sobre permisos:** `chmod 775` es un buen punto de partida. Sin embargo, durante el despliegue de Laravel, las carpetas `storage` y `bootstrap/cache` dentro de `/var/www/laravel-app` **necesitarán permisos de escritura** para el usuario `www-data`. Esto generalmente se logra estableciendo permisos `775` y asegurándose de que `www-data` sea parte del grupo propietario, o `777` si tienes problemas y necesitas una solución rápida (menos segura). Idealmente, asegúrate de que el propietario sea `laravelapp` y el grupo sea `www-data` o `laravelapp` y que ambos usuarios puedan escribir.

2. **Crear el archivo de configuración de Nginx para tu aplicación:**

    ```bash
    sudo nano /etc/nginx/sites-available/laravel-app.conf
    ```

    Pega el siguiente contenido (reemplaza `vps_ip_address` con la IP de tu servidor o `your_domain.com` si ya tienes un dominio apuntando a la IP, y `/var/www/laravel-app` con la ruta de tu aplicación).

    ```nginx
    server {
        listen 80;
        listen [::]:80;
        server_name vps_ip_address your_domain.com www.your_domain.com;
        root /var/www/laravel-app/public;

        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Content-Type-Options "nosniff";

        client_max_body_size 10M;

        index index.php;

        charset utf-8;

        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }

        location /app {
            proxy_pass http://127.0.0.1:9000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 86400;
            proxy_send_timeout 86400;
        }

        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        error_page 404 /index.php;

        location ~ \.php$ {
            fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
            include fastcgi_params;
            fastcgi_hide_header X-Powered-By;
        }

        location ~ /\.(?!well-known).* {
            deny all;
        }
    }
    ```

3. **Habilitar la configuración creando un enlace simbólico:**

    ```bash
    sudo ln -s /etc/nginx/sites-available/laravel-app.conf /etc/nginx/sites-enabled/
    ```

4. **Eliminar la configuración por defecto de Nginx (para evitar conflictos):**

    ```bash
    sudo rm /etc/nginx/sites-enabled/default
    ```

5. **Probar la configuración de Nginx para errores de sintaxis:**

    ```bash
    sudo nginx -t
    ```

    Debería mostrar `syntax is ok` y `test is successful`.

6. **Reiniciar Nginx para aplicar los cambios:**

    ```bash
    sudo systemctl restart nginx
    ```

## 10. Seguridad Adicional (Opcional, pero Recomendado)

### Certificados SSL con Let's Encrypt (Certbot)

Una vez que tu dominio apunte a tu VPS y tengas tu configuración de Nginx, puedes instalar un certificado SSL gratuito con Certbot para HTTPS.

```bash
sudo apt install certbot python3-certbot-nginx -y
```

Ejecuta Certbot para obtener el certificado y configurar Nginx automáticamente (reemplaza `your_domain.com` y `www.your_domain.com` con tus dominios reales):

```bash
sudo certbot --nginx -d your_domain.com -d www.your_domain.com
```

Sigue las instrucciones en pantalla. Esto modificará tu archivo de configuración de Nginx para incluir HTTPS y redirigir el tráfico HTTP a HTTPS.
