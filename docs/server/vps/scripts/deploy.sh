#!/bin/bash

# ==============================================================================
# Configuración
# ==============================================================================

APP_DIR="/var/www/medrush-app"
LARAVEL_REPO_SUBDIR="app"
LARAVEL_ROOT_RELATIVE="${LARAVEL_REPO_SUBDIR}/server"

GIT_BRANCH="main"

APP_USER="test"
WEB_SERVER_USER="www-data"

GIT_REPO_URL="git@github.com:rasoky2/MedRushApp.git"

COMPOSER_BIN="/usr/local/bin/composer"

SUPERVISOR_WORKER_PROGRAM="laravel-worker:*"
SUPERVISOR_REVERB_PROGRAM="laravel-reverb"

# ==============================================================================
# Funciones Auxiliares
# ==============================================================================

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

exit_on_error() {
    log_message "ERROR: $1"
    exit 1
}

# ==============================================================================
# Inicio del Proceso de Despliegue
# ==============================================================================

log_message "Iniciando el despliegue de la aplicación Laravel"
log_message "Directorio principal de la aplicación: ${APP_DIR}"
log_message "Raíz del proyecto Laravel: ${APP_DIR}/${LARAVEL_ROOT_RELATIVE}"
log_message "Rama Git: ${GIT_BRANCH}"
log_message "Usuario de despliegue (Git/Composer/Artisan): ${APP_USER}"
log_message "Usuario del servidor web (Permisos de ejecución): ${WEB_SERVER_USER}"

# Rutas completas
APP_REPO_PATH="${APP_DIR}/${LARAVEL_REPO_SUBDIR}"
LARAVEL_ACTUAL_ROOT="${APP_DIR}/${LARAVEL_ROOT_RELATIVE}"
PRIVATE_DIR="${APP_DIR}/private"
PRIVATE_ENV_FILE="${PRIVATE_DIR}/.env"
# PRIVATE_SERVICES_DIR="${PRIVATE_DIR}/services"
LARAVEL_ENV_SYMLINK="${LARAVEL_ACTUAL_ROOT}/.env"
LARAVEL_STORAGE_DIR="${LARAVEL_ACTUAL_ROOT}/storage"
LARAVEL_STORAGE_SERVICES_SYMLINK="${LARAVEL_STORAGE_DIR}/services"
LARAVEL_BOOTSTRAP_CACHE_DIR="${LARAVEL_ACTUAL_ROOT}/bootstrap/cache"

# 1. Crear el directorio principal de la aplicación si no existe
if [ ! -d "$APP_DIR" ]; then
    log_message "Creando el directorio principal de la aplicación: $APP_DIR"
    sudo mkdir -p "$APP_DIR" || exit_on_error "No se pudo crear el directorio principal de la aplicación."
    sudo chown "$APP_USER:$APP_USER" "$APP_DIR" || exit_on_error "Fallo al cambiar la propiedad del directorio $APP_DIR."
fi


# 2. Asegurarse de que los directorios privados existan y tengan los permisos correctos
log_message "Verificando/creando directorios privados: $PRIVATE_DIR y $PRIVATE_SERVICES_DIR"
if [ ! -d "$PRIVATE_DIR" ]; then
    sudo mkdir -p "$PRIVATE_DIR" || exit_on_error "No se pudo crear el directorio privado: $PRIVATE_DIR"
    sudo chown "$APP_USER:$APP_USER" "$PRIVATE_DIR" || exit_on_error "Fallo al cambiar la propiedad del directorio $PRIVATE_DIR."
fi
# if [ ! -d "$PRIVATE_SERVICES_DIR" ]; then
#     sudo mkdir -p "$PRIVATE_SERVICES_DIR" || exit_on_error "No se pudo crear el directorio de servicios privados: $PRIVATE_SERVICES_DIR"
#     sudo chown "$APP_USER:$APP_USER" "$PRIVATE_SERVICES_DIR" || exit_on_error "Fallo al cambiar la propiedad del directorio $PRIVATE_SERVICES_DIR."
# fi
# Asegurarse de que el .env original exista o crearlo si no.
if [ ! -f "$PRIVATE_ENV_FILE" ]; then
    log_message "El archivo .env original no existe en $PRIVATE_ENV_FILE. Creando uno vacío."
    sudo -u "$APP_USER" touch "$PRIVATE_ENV_FILE" || exit_on_error "Fallo al crear el archivo .env original."
    sudo chmod 660 "$PRIVATE_ENV_FILE" || exit_on_error "Fallo al establecer permisos para .env original."
fi


# 3. Preparar el directorio donde se clonará el repositorio
log_message "Preparando el directorio del repositorio: ${APP_REPO_PATH}"
if [ ! -d "$APP_REPO_PATH" ]; then
    sudo mkdir -p "$APP_REPO_PATH" || exit_on_error "No se pudo crear el directorio para el repositorio: $APP_REPO_PATH"
    sudo chown "$APP_USER:$APP_USER" "$APP_REPO_PATH" || exit_on_error "Fallo al cambiar la propiedad del directorio $APP_REPO_PATH."
fi

# Cambiar al directorio del repositorio para operaciones Git
cd "$APP_REPO_PATH" || exit_on_error "No se pudo cambiar al directorio del repositorio: $APP_REPO_PATH"


# 4. Clonar o actualizar el repositorio Git
if [ ! -d ".git" ]; then
    log_message "El repositorio Git no existe en ${APP_REPO_PATH}. Clonando..."
    sudo -u "$APP_USER" git clone "$GIT_REPO_URL" . || exit_on_error "Fallo al clonar el repositorio."
    sudo chown -R "$APP_USER:$APP_USER" . || exit_on_error "Fallo al cambiar la propiedad del directorio clonado."
else
    log_message "El repositorio Git ya existe. Obteniendo los últimos cambios de la rama ${GIT_BRANCH}..."
    sudo -u "$APP_USER" git fetch origin || exit_on_error "Fallo al ejecutar git fetch."
    sudo -u "$APP_USER" git reset --hard "origin/${GIT_BRANCH}" || exit_on_error "Fallo al ejecutar git reset --hard."
    sudo -u "$APP_USER" git clean -df || exit_on_error "Fallo al ejecutar git clean."
    log_message "Código actualizado."
fi

# 5. Cambiar a la raíz de Laravel para operaciones de Composer y Artisan
log_message "Cambiando a la raíz del proyecto Laravel: ${LARAVEL_ACTUAL_ROOT}"
cd "$LARAVEL_ACTUAL_ROOT" || exit_on_error "No se pudo cambiar a la raíz de Laravel: $LARAVEL_ACTUAL_ROOT."


# 6. Crear enlaces simbólicos para .env y services
log_message "Creando/verificando enlaces simbólicos para .env y services..."

# Enlace simbólico para .env
if [ -L "$LARAVEL_ENV_SYMLINK" ]; then
    if [ "$(readlink "$LARAVEL_ENV_SYMLINK")" != "$PRIVATE_ENV_FILE" ]; then
        log_message "El enlace simbólico de .env apunta a otro lugar. Removiendo y recreando."
        rm "$LARAVEL_ENV_SYMLINK" || exit_on_error "No se pudo remover el enlace simbólico de .env existente."
        sudo -u "$APP_USER" ln -s "$PRIVATE_ENV_FILE" "$LARAVEL_ENV_SYMLINK" || exit_on_error "Fallo al crear el enlace simbólico para .env (recrear)."
    else
        log_message "El enlace simbólico de .env ya es correcto."
    fi
elif [ -f "$LARAVEL_ENV_SYMLINK" ]; then # Si es un archivo regular
    log_message ".env es un archivo regular, removiendo y creando enlace simbólico."
    rm "$LARAVEL_ENV_SYMLINK" || exit_on_error "No se pudo remover el archivo .env existente."
    sudo -u "$APP_USER" ln -s "$PRIVATE_ENV_FILE" "$LARAVEL_ENV_SYMLINK" || exit_on_error "Fallo al crear el enlace simbólico para .env (archivo regular)."
else
    sudo -u "$APP_USER" ln -s "$PRIVATE_ENV_FILE" "$LARAVEL_ENV_SYMLINK" || exit_on_error "Fallo al crear el enlace simbólico para .env (no existe)."
fi
log_message "Enlace simbólico para .env verificado/creado."

# Enlace simbólico para storage/services
# sudo -u "$APP_USER" mkdir -p "$LARAVEL_STORAGE_DIR" || exit_on_error "No se pudo crear el directorio storage para el enlace simbólico de services."

# if [ -L "$LARAVEL_STORAGE_SERVICES_SYMLINK" ]; then
#     if [ "$(readlink "$LARAVEL_STORAGE_SERVICES_SYMLINK")" != "$PRIVATE_SERVICES_DIR" ]; then
#         log_message "El enlace simbólico de services apunta a otro lugar. Removiendo y recreando."
#         rm "$LARAVEL_STORAGE_SERVICES_SYMLINK" || exit_on_error "No se pudo remover el enlace simbólico de services existente."
#         sudo -u "$APP_USER" ln -s "$PRIVATE_SERVICES_DIR" "$LARAVEL_STORAGE_SERVICES_SYMLINK" || exit_on_error "Fallo al crear el enlace simbólico para services (recrear)."
#     else
#         log_message "El enlace simbólico de services ya es correcto."
#     fi
# elif [ -d "$LARAVEL_STORAGE_SERVICES_SYMLINK" ]; then
#     log_message "services es un directorio regular, removiendo y creando enlace simbólico."
#     rm -rf "$LARAVEL_STORAGE_SERVICES_SYMLINK" || exit_on_error "No se pudo remover el directorio services existente."
#     sudo -u "$APP_USER" ln -s "$PRIVATE_SERVICES_DIR" "$LARAVEL_STORAGE_SERVICES_SYMLINK" || exit_on_error "Fallo al crear el enlace simbólico para services (directorio regular)."
# else
#     sudo -u "$APP_USER" ln -s "$PRIVATE_SERVICES_DIR" "$LARAVEL_STORAGE_SERVICES_SYMLINK" || exit_on_error "Fallo al crear el enlace simbólico para services (no existe)."
# fi
# log_message "Enlace simbólico para services verificado/creado."


# 7. Instalar/Actualizar dependencias de Composer
log_message "Instalando/Actualizando dependencias de Composer..."
# sudo -u "$APP_USER" "$COMPOSER_BIN" install --no-dev --optimize-autoloader --prefer-dist || exit_on_error "Fallo al ejecutar Composer install."
sudo -u "$APP_USER" "$COMPOSER_BIN" install || exit_on_error "Fallo al ejecutar Composer install."
log_message "Dependencias de Composer instaladas."


# 9. Ejecutar migraciones de la base de datos
log_message "Ejecutando migraciones de la base de datos..."
sudo -u "$APP_USER" php artisan migrate --force || exit_on_error "Fallo al ejecutar las migraciones de la base de datos."
log_message "Migraciones de la base de datos completadas."


# 10. Limpiar y optimizar cachés de Laravel
log_message "Limpiando y optimizando cachés de Laravel..."
sudo -u "$APP_USER" php artisan optimize:clear || exit_on_error "Fallo al limpiar las cachés de Laravel."
sudo -u "$APP_USER" php artisan config:cache || exit_on_error "Fallo al cachear la configuración."
sudo -u "$APP_USER" php artisan route:cache || exit_on_error "Fallo al cachear las rutas."
# sudo -u "$APP_USER" php artisan view:cache || exit_on_error "Fallo al cachear las vistas."
log_message "Cachés de Laravel optimizadas."


# 11. Reiniciar programas de Supervisor (Reverb y Workers)
log_message "Reiniciando los procesos de Supervisor..."

# Reverb
log_message "Reiniciando Reverb (${SUPERVISOR_REVERB_PROGRAM})..."
sudo supervisorctl restart "$SUPERVISOR_REVERB_PROGRAM" || exit_on_error "Fallo al reiniciar Reverb con Supervisor."

# Workers
log_message "Reiniciando Workers (${SUPERVISOR_WORKER_PROGRAM})..."
sudo supervisorctl restart "$SUPERVISOR_WORKER_PROGRAM" || exit_on_error "Fallo al reiniciar los Workers con Supervisor."

log_message "Programas de Supervisor reiniciados."

# 12. Ajustar permisos de directorios para el servidor web
log_message "Ajustando permisos de almacenamiento y caché para el usuario del servidor web (${WEB_SERVER_USER})..."
sudo chown -R "$WEB_SERVER_USER:$WEB_SERVER_USER" "$LARAVEL_STORAGE_DIR" "$LARAVEL_BOOTSTRAP_CACHE_DIR" || exit_on_error "Fallo al ajustar la propiedad de los directorios."
sudo chmod -R ug+rwx "$LARAVEL_STORAGE_DIR" "$LARAVEL_BOOTSTRAP_CACHE_DIR" || exit_on_error "Fallo al ajustar los permisos de escritura de los directorios."
log_message "Permisos ajustados para ${WEB_SERVER_USER}."

log_message "Despliegue completado exitosamente."
