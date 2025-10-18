#!/bin/bash

# --- Configuración Inicial ---
APP_USER="laravelapp"
APP_DIR="/var/www/laravel-app"
DB_USER="your_db_user"
DB_PASSWORD="your_db_password"
DB_NAME="your_db_name"
VPS_IP="your_vps_ip_address"
DOMAIN="your_domain.com"

PHP_VERSION="8.2"

# --- Funciones de Utilidad ---
log_info() {
    echo -e "\n\e[1;34m[INFO]\e[0m $1"
}

log_success() {
    echo -e "\n\e[1;32m[ÉXITO]\e[0m $1"
}

log_error() {
    echo -e "\n\e[1;31m[ERROR]\e[0m $1"
}

log_warning() {
    echo -e "\n\e[1;33m[ADVERTENCIA]\e[0m $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script debe ejecutarse como usuario root o con sudo."
        exit 1
    fi
}

check_root

log_info "Iniciando la preparación del VPS para Laravel (Debian 12)..."
log_info "Configuración de variables:"
echo "  Usuario de la aplicación: $APP_USER"
echo "  Directorio de la aplicación: $APP_DIR"
echo "  Usuario de la BD: $DB_USER"
echo "  Nombre de la BD: $DB_NAME"
echo "  IP del VPS: $VPS_IP"
echo "  Dominio: $DOMAIN"
echo "  Versión de PHP: $PHP_VERSION"

read -p "¿Son correctas estas configuraciones? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_error "Configuración cancelada. Por favor, edita las variables en el script."
    exit 1
fi

# 1. Acceso al VPS y Configuración Inicial del Usuario
log_info "1. Creando usuario '$APP_USER' y otorgando privilegios sudo..."
if id "$APP_USER" &>/dev/null; then
    log_warning "El usuario '$APP_USER' ya existe. Omitiendo la creación del usuario."
else
    echo "Por favor, introduce la contraseña para el nuevo usuario '$APP_USER':"
    adduser "$APP_USER"
    if [ $? -ne 0 ]; then log_error "Error al crear el usuario '$APP_USER'."; exit 1; fi
fi
usermod -aG sudo "$APP_USER"
if [ $? -ne 0 ]; then log_error "Error al añadir '$APP_USER' al grupo sudo."; exit 1; fi
log_success "Usuario '$APP_USER' creado y añadido al grupo sudo."
log_warning "¡IMPORTANTE! Una vez que este script termine, deberías salir y volver a conectarte como '$APP_USER' para continuar con tus despliegues."

# 2. Actualizar el Sistema
log_info "2. Actualizando el sistema..."
apt update && apt upgrade -y
if [ $? -ne 0 ]; then log_error "Error durante la actualización del sistema."; exit 1; fi
log_success "Sistema actualizado."

# 3. Instalar Nginx
log_info "3. Instalando Nginx..."
apt install nginx -y
if [ $? -ne 0 ]; then log_error "Error al instalar Nginx."; exit 1; fi
systemctl enable nginx && systemctl start nginx
if [ $? -ne 0 ]; then log_error "Error al iniciar/habilitar Nginx."; exit 1; fi
log_success "Nginx instalado y corriendo."

# 4. Instalar PostgreSQL y PostGIS
log_info "4. Instalando PostgreSQL y PostGIS..."
apt install postgresql postgresql-contrib postgis -y
if [ $? -ne 0 ]; then log_error "Error al instalar PostgreSQL/PostGIS."; exit 1; fi
systemctl enable postgresql && systemctl start postgresql
if [ $? -ne 0 ]; then log_error "Error al iniciar/habilitar PostgreSQL."; exit 1; fi
log_success "PostgreSQL y PostGIS instalados y corriendo."

log_info "Configurando usuario y base de datos en PostgreSQL..."
# Crear usuario y base de datos de forma segura
sudo -u postgres psql -c "CREATE USER \"$DB_USER\" WITH PASSWORD '$DB_PASSWORD';"
if [ $? -ne 0 ]; then log_error "Error al crear el usuario de PostgreSQL."; exit 1; fi
sudo -u postgres psql -c "CREATE DATABASE \"$DB_NAME\" OWNER \"$DB_USER\";"
if [ $? -ne 0 ]; then log_error "Error al crear la base de datos de PostgreSQL."; exit 1; fi
sudo -u postgres psql -d "$DB_NAME" -c "CREATE EXTENSION postgis;"
if [ $? -ne 0 ]; then log_error "Error al habilitar PostGIS."; exit 1; fi
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\";"
if [ $? -ne 0 ]; then log_error "Error al otorgar privilegios al usuario de PostgreSQL."; exit 1; fi
log_success "Base de datos '$DB_NAME' y usuario '$DB_USER' creados con PostGIS habilitado."

# 5. Instalar PHP y Extensiones Necesarias
log_info "5. Instalando PHP $PHP_VERSION y extensiones..."
apt install curl ca-certificates gnupg -y
curl -sSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/deb.sury.org-php.gpg
echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ bookworm main" | tee /etc/apt/sources.list.d/sury-php.list
apt update

PHP_PACKAGES="php${PHP_VERSION}-fpm php${PHP_VERSION}-common php${PHP_VERSION}-cli php${PHP_VERSION}-curl php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-gd php${PHP_VERSION}-pgsql php${PHP_VERSION}-bcmath php${PHP_VERSION}-soap php${PHP_VERSION}-intl php${PHP_VERSION}-readline"
apt install $PHP_PACKAGES -y
if [ $? -ne 0 ]; then log_error "Error al instalar PHP $PHP_VERSION y extensiones."; exit 1; fi

systemctl enable php${PHP_VERSION}-fpm && systemctl start php${PHP_VERSION}-fpm
if [ $? -ne 0 ]; then log_error "Error al iniciar/habilitar PHP-FPM."; exit 1; fi
log_success "PHP $PHP_VERSION y extensiones instaladas y PHP-FPM corriendo."

# 6. Instalar Composer
log_info "6. Instalando Composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer
if [ $? -ne 0 ]; then log_error "Error al instalar Composer."; exit 1; fi
log_success "Composer instalado."

# 7. Instalar Node.js y npm
log_info "7. Instalando Node.js y npm (para Laravel Reverb)..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs
if [ $? -ne 0 ]; then log_error "Error al instalar Node.js/npm."; exit 1; fi
log_success "Node.js y npm instalados."

# 8. Instalar Supervisor
log_info "8. Instalando Supervisor..."
apt install supervisor -y
if [ $? -ne 0 ]; then log_error "Error al instalar Supervisor."; exit 1; fi
systemctl enable supervisor && systemctl start supervisor
if [ $? -ne 0 ]; then log_error "Error al iniciar/habilitar Supervisor."; exit 1; fi
log_success "Supervisor instalado y corriendo."

log_info "Configurando Supervisor para Laravel Worker y Reverb..."

# Crear directorios de logs si no existen, y asegurar permisos para www-data
mkdir -p "$APP_DIR/storage/logs"
chown -R "$APP_USER":"$APP_USER" "$APP_DIR"
chmod -R 775 "$APP_DIR"

# Ajustar pertenencia a grupos para que www-data y laravelapp puedan interactuar fácilmente
usermod -aG "$APP_USER" www-data
usermod -aG www-data "$APP_USER"
log_success "Ajustados permisos iniciales para $APP_DIR y pertenencia a grupos."

# Configuración del worker
cat <<EOF > /etc/supervisor/conf.d/laravel-worker.conf
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php $APP_DIR/artisan queue:work --timeout=600 --sleep=3 --tries=2 --max-time=1800
directory=$APP_DIR
autostart=true
autorestart=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=$APP_DIR/storage/logs/queue-worker.log
stopwaitsecs=3600
EOF

# Configuración de Reverb
cat <<EOF > /etc/supervisor/conf.d/laravel-reverb.conf
[program:laravel-reverb]
command=php $APP_DIR/artisan reverb:start --host=0.0.0.0 --port=9000 --debug
directory=$APP_DIR
numprocs=1
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=$APP_DIR/storage/logs/reverb.log
stopwaitsecs=3600
EOF

supervisorctl reread
supervisorctl update
if [ $? -ne 0 ]; then log_error "Error al actualizar las configuraciones de Supervisor."; exit 1; fi
log_success "Supervisor configurado para Laravel Worker y Reverb."
log_warning "Nota: Los procesos de Supervisor no se iniciarán hasta que $APP_DIR contenga una aplicación Laravel válida."

# 9. Configuración del Servidor Web (Nginx)
log_info "9. Configurando Nginx para la aplicación Laravel..."

# Crear directorio si no existe (ya se hizo arriba pero repetimos por seguridad)
mkdir -p "$APP_DIR"
chown -R "$APP_USER":"$APP_USER" "$APP_DIR"
chmod -R 775 "$APP_DIR"

# Nginx config
NGINX_CONF="/etc/nginx/sites-available/laravel-app.conf"
PHP_SOCKET="/var/run/php/php${PHP_VERSION}-fpm.sock"

cat <<EOF > "$NGINX_CONF"
server {
    listen 80;
    listen [::]:80;
    server_name $VPS_IP $DOMAIN www.$DOMAIN;
    root $APP_DIR/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    client_max_body_size 10M;

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location /app {
        proxy_pass http://127.0.0.1:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:$PHP_SOCKET;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\\.(?!well-known).* {
        deny all;
    }
}
EOF

ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
if [ $? -ne 0 ]; then log_error "Error en la configuración de Nginx. Por favor, revisa el archivo $NGINX_CONF."; exit 1; fi

systemctl restart nginx
if [ $? -ne 0 ]; then log_error "Error al reiniciar Nginx."; exit 1; fi
log_success "Nginx configurado y reiniciado."

# 10. Seguridad Adicional - Certificados SSL
log_info "10. Instalando Certbot para SSL (opcional)..."
read -p "¿Quieres instalar Certbot para HTTPS ahora? (s/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    apt install certbot python3-certbot-nginx -y
    if [ $? -ne 0 ]; then log_error "Error al instalar Certbot."; exit 1; fi
    log_info "Ejecutando Certbot. Sigue las instrucciones en pantalla."
    log_warning "Asegúrate de que tu dominio ($DOMAIN) apunte a la IP de este VPS antes de ejecutar Certbot."
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN"
    if [ $? -ne 0 ]; then log_error "Error al configurar SSL con Certbot."; fi
    log_success "Certbot ejecutado. Revisa la configuración de SSL."
else
    log_warning "Certbot no instalado. Tu sitio no tendrá HTTPS a menos que lo configures manualmente."
fi

log_success "Script de preparación del VPS para Laravel completado."
