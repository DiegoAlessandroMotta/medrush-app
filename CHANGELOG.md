# Changelog - Cambios del Pull Request

**Fecha:** Actualización desde `5cf126c` a `df355c3`  
**Archivos modificados:** 22 archivos  
**Líneas:** +314 adiciones, -73 eliminaciones

---

## Resumen

Esta actualización incluye mejoras significativas en el manejo de pedidos, reportes de errores del cliente, seguimiento de uso de APIs de Google, y mejoras en el procesamiento masivo de pedidos mediante CSV.

---

## Nuevos Modelos

### 1. `GoogleApiUsage` (`server/app/Models/GoogleApiUsage.php`)
- **Propósito:** Rastrear el uso de las APIs de Google por usuario
- **Campos principales:**
  - `user_id` (UUID, nullable): Relación con el usuario
  - `type` (enum `GoogleApiServiceType`): Tipo de servicio utilizado
- **Relaciones:**
  - `belongsTo(User::class)`: Relación con el modelo User

### 2. `ReportePdf` (`server/app/Models/ReportePdf.php`)
- **Propósito:** Gestionar la generación y almacenamiento de reportes PDF
- **Campos principales:**
  - `user_id` (UUID): Usuario que solicita el reporte
  - `nombre` (string): Nombre del reporte
  - `file_path` (string, nullable): Ruta del archivo PDF generado
  - `file_size` (int, nullable): Tamaño del archivo en bytes
  - `paginas` (int, nullable): Número de páginas del PDF
  - `page_size` (enum `PageSizeEnum`): Tamaño de página del PDF
  - `pedidos` (array): Lista de IDs de pedidos incluidos en el reporte
  - `status` (enum `EstadoReportePdfEnum`): Estado del reporte (EN_PROCESO, CREADO, FALLIDO, EXPIRADO)
- **Métodos principales:**
  - `markAsInProcess()`, `markAsCreated()`, `markAsFailed()`, `markAsExpired()`
  - `deleteFromDisk()`, `existsOnDisk()`, `sizeOnDisk()`
  - `getReadableFileSize()`: Formatea el tamaño del archivo en unidades legibles
  - `getSignedUrl()`: Genera URL temporal firmada válida por 60 minutos
  - `saveToDisk()`: Guarda el contenido del PDF en el disco
- **Relaciones:**
  - `belongsTo(User::class)`: Relación con el modelo User

---

## Modelos Modificados

### 1. `ClientError` (`server/app/Models/ClientError.php`)
- **Cambios:** Se añadieron campos y métodos para mejorar el manejo de errores reportados por clientes
- **Nuevos campos:**
  - `context` (array): Almacena información contextual del error (error_type, platform, message, etc.)

### 2. `Pedido` (`server/app/Models/Pedido.php`)
- **Cambios:** Ajustes menores en las relaciones y propiedades del modelo

### 3. `PerfilRepartidor` (`server/app/Models/PerfilRepartidor.php`)
- **Cambios:** Se añadieron campos adicionales para documentación del vehículo y permisos
- **Nuevos campos documentados:**
  - `vehiculo_anio`, `vehiculo_color`, `vehiculo_vin_chasis`, `vehiculo_tipo`, `vehiculo_capacidad_carga`
  - `soat_numero`, `soat_vencimiento`, `foto_soat_path`
  - `revision_tecnica_numero`, `revision_tecnica_vencimiento`, `foto_revision_tecnica_path`
  - `tarjeta_circulacion_numero`, `foto_tarjeta_circulacion_path`
  - `registro_estatal_numero`, `registro_estatal_vencimiento`, `foto_registro_estatal_path`
  - `inspeccion_numero`, `inspeccion_vencimiento`, `foto_inspeccion_path`

### 4. `User` (`server/app/Models/User.php`)
- **Cambios:** Se añadieron nuevas relaciones
- **Nuevas relaciones:**
  - `googleApiUsages()`: `HasMany` relación con `GoogleApiUsage`
  - `reportesPdf()`: `HasMany` relación con `ReportePdf`
  - `clientErrors()`: `HasMany` relación con `ClientError`

---

## Controladores Modificados

### 1. `ClientErrorController` (`server/app/Http/Controllers/ClientErrorController.php`)
- **Métodos mejorados:**
  - `report()`: Ahora incluye `ip_address`, `user_agent` y `reported_at` en el contexto del error
  - `index()`: Filtros mejorados para búsqueda por tipo de error, plataforma, usuario y fechas
  - `show()`: Nuevo método para mostrar detalles de un error específico

### 2. `PedidoController` (`server/app/Http/Controllers/Entities/PedidoController.php`)
- **Mejoras principales:**
  - `show()`: Ahora usa `PedidoRepartidorResource` cuando el usuario es un repartidor, proporcionando una vista optimizada para entregadores
  - `uploadCsv()`: Validación mejorada de farmacia y manejo de ubicación de recogida
  - Mejoras en la paginación y filtros del método `index()`

---

## Requests Modificados

### 1. `IndexPedidoRequest` (`server/app/Http/Requests/Pedido/IndexPedidoRequest.php`)
- **Cambios:** Se añadió soporte para filtro por `repartidor_id`
- **Nuevo método:** `hasRepartidorId()` y `getRepartidorId()`

### 2. `StorePedidoRequest` (`server/app/Http/Requests/Pedido/StorePedidoRequest.php`)
- **Cambios:** Mejoras en la validación de `ubicacion_recojo` y `codigo_iso_pais_entrega`
- **Lógica mejorada:** Si no se proporciona `ubicacion_recojo`, se usa automáticamente la ubicación de la farmacia

### 3. `UploadCsvFileRequest` (`server/app/Http/Requests/UploadCsvFileRequest.php`)
- **Cambios significativos:**
  - Validación mejorada con mensajes personalizados en español
  - Validación condicional: `codigo_iso_pais_entrega` y `ubicacion_recojo` son requeridos si no se proporciona `farmacia_id`
  - Nuevos métodos helper: `getFarmacia()`, `getCodigoIsoPaisEntrega()`, `getUbicacionRecojo()`
  - Validación de existencia de farmacia en `after()` hook

### 4. `RegisterRepartidorUserRequest` (`server/app/Http/Requests/Register/RegisterRepartidorUserRequest.php`)
- **Cambios:** Ajustes menores en validación

### 5. `UpdateRepartidorUserRequest` (`server/app/Http/Requests/User/Update/UpdateRepartidorUserRequest.php`)
- **Cambios:** Ajustes menores en validación

---

## Nuevos Resources

### 1. `PedidoRepartidorResource` (`server/app/Http/Resources/Pedido/PedidoRepartidorResource.php`)
- **Propósito:** Resource especializado para la vista de pedidos desde la perspectiva del repartidor
- **Características:**
  - Oculta información sensible de la farmacia
  - Proporciona URLs firmadas para fotos de entrega
  - Serializa ubicaciones usando `AsPoint::serializeValue()`
  - Incluye información completa del repartidor cuando está cargada la relación

### 2. `PerfilRepartidorResource` (`server/app/Http/Resources/PerfilRepartidorResource.php`)
- **Cambios:** Se añadió un campo adicional en el resource

---

## Jobs Modificados

### 1. `ProcessPedidosCsv` (`server/app/Jobs/ProcessPedidosCsv.php`)
- **Mejoras significativas:**
  - **Manejo de memoria optimizado:** Procesamiento por chunks para evitar sobrecarga de memoria
  - **Validación mejorada:** Validación de farmacia antes de procesar el CSV
  - **Generación de códigos de barras:** Soporte para offset en la generación de códigos
  - **Manejo de ubicaciones:** Mejor procesamiento de `ubicacion_recojo` y `ubicacion_entrega`
  - **Notificaciones mejoradas:** Notificaciones más detalladas sobre el progreso del procesamiento
  - **Logging mejorado:** Logs de memoria durante el procesamiento para monitoreo
  - **Limpieza de archivos:** Eliminación automática del archivo CSV después del procesamiento

---

## Servicios Modificados

### 1. `GeocodingService` (`server/app/Services/Geocoding/GeocodingService.php`)
- **Cambios:**
  - **Tracking de uso:** Registra cada llamada a la API de Google Geocoding en la tabla `google_api_usages`
  - **Asociación con usuario:** Vincula el uso de la API con el usuario autenticado
  - Mejoras en el manejo de errores y logging

---

## Validadores Modificados

### 1. `CsvPedidoRowValidator` (`server/app/Validators/CsvPedidoRowValidator.php`)
- **Cambios:** Ajustes menores en la validación de filas CSV

---

## Migraciones (Implícitas)

### 1. `create_perfiles_repartidor_table`
- **Cambios:** Ajustes en la estructura de la tabla

### 2. `create_pedidos_table`
- **Cambios:** Ajustes en la estructura de la tabla

---

## Archivos Eliminados

### 1. `server/tests/Unit/ExampleTest.php`
- **Razón:** Test de ejemplo eliminado para mantener el código limpio

---

## Eventos y Servicios

### 1. `PedidoEventService` (`server/app/Services/PedidoEventService.php`)
- **Cambios:** Ajustes menores en el servicio

---

## Impacto y Consideraciones

### Mejoras en Rendimiento
- El procesamiento de CSV ahora es más eficiente en memoria mediante chunks
- Caché implementado en el servicio de geocodificación

### Nuevas Funcionalidades
- **Tracking de APIs de Google:** Permite monitorear el uso de servicios externos
- **Sistema de reportes PDF:** Base para generar reportes de pedidos
- **Vista especializada para repartidores:** Mejora la experiencia de usuario para entregadores

### Seguridad
- Validación mejorada en uploads de CSV
- URLs firmadas para acceso temporal a archivos privados
- Registro de IP y User-Agent en reportes de errores del cliente

### Mantenibilidad
- Código más organizado con recursos especializados
- Mejor separación de responsabilidades
- Logging mejorado para debugging

---

## Notas para Desarrolladores

1. **Nuevas dependencias de base de datos:** Se requieren nuevas tablas para `google_api_usages` y `reportes_pdf`
2. **Migrations:** Ejecutar `php artisan migrate` para aplicar cambios en la estructura de la base de datos
3. **Configuración:** Verificar que `services.google.geocoding.api_key` esté configurado correctamente
4. **Permisos:** Asegurar que los usuarios tengan los permisos correctos para acceder a las nuevas funcionalidades

---

## Próximos Pasos Recomendados

- [ ] Ejecutar migraciones
- [ ] Verificar configuración de Google API
- [ ] Probar procesamiento masivo de CSV con diferentes tamaños
- [ ] Validar que las notificaciones lleguen correctamente a los usuarios
- [ ] Revisar permisos y roles para las nuevas funcionalidades

