# Guía Completa para Configurar Servicios de Google Cloud y Firebase

## Tabla de Contenidos
1. [Introducción](#introducción)
2. [Configuración de Google Cloud Platform](#configuración-de-google-cloud-platform)
3. [Configuración de Firebase Messaging](#configuración-de-firebase-messaging)
4. [Configuración de VPS](#configuración-de-vps)
5. [Comparativa de Proveedores VPS](#comparativa-de-proveedores-vps)
6. [Configuración del Servidor](#configuración-del-servidor)
7. [Consideraciones de Costos](#consideraciones-de-costos)
8. [Preguntas Frecuentes](#preguntas-frecuentes)

## Introducción

Esta guía te ayudará a configurar todos los servicios necesarios para que tu aplicación MedRush funcione correctamente. Necesitarás configurar servicios de Google Cloud para las APIs de mapas y geocodificación, Firebase para las notificaciones push, y un servidor VPS para alojar tu backend.

## Configuración de Google Cloud Platform

### ¿Por qué necesitas Google Cloud Platform?

Google Cloud Platform (GCP) es necesario para acceder a las siguientes APIs que utiliza tu aplicación:

- **Google Maps API**: Para mostrar mapas interactivos
- **Google Geocoding API**: Para convertir direcciones en coordenadas y viceversa
- **Google Places API**: Para buscar lugares y direcciones
- **Google Directions API**: Para calcular rutas entre puntos
- **Google Route Optimization API**: Para optimizar rutas de entrega

### Paso 1: Crear una cuenta en Google Cloud

1. **Visita Google Cloud Console**
   - Ve a [console.cloud.google.com](https://console.cloud.google.com)
   - Haz clic en "Get started for free" o "Comenzar gratis"

2. **Crear una cuenta Google**
   - Si no tienes una cuenta Google, crea una nueva
   - Usa un email profesional para tu empresa

3. **Verificar tu identidad**
   - Google te pedirá verificar tu número de teléfono
   - Acepta los términos y condiciones

### Paso 2: Configurar la facturación

**IMPORTANTE**: Google Cloud requiere una tarjeta de crédito para activar la facturación, pero te ofrece $300 USD en créditos gratuitos por 90 días.

1. **Activar la facturación**
   - En el menú lateral, ve a "Billing" (Facturación)
   - Haz clic en "Link a billing account" (Vincular una cuenta de facturación)
   - Selecciona "Create new billing account" (Crear nueva cuenta de facturación)

2. **Completar la información de facturación**
   - País: Selecciona tu país
   - Tipo de cuenta: Individual o Empresarial
   - Información de contacto: Completa tus datos
   - Método de pago: Agrega tu tarjeta de crédito

3. **Configurar alertas de facturación**
   - Establece alertas cuando el gasto alcance $50, $100, $200
   - Esto te ayudará a controlar los costos

### Paso 3: Crear un proyecto

1. **Crear nuevo proyecto**
   - En la consola, haz clic en el selector de proyectos
   - Selecciona "New Project"
   - Nombre del proyecto: "MedRush-Production"
   - Organización: Selecciona tu organización o deja en blanco

2. **Habilitar APIs necesarias**
   - Ve a "APIs & Services" > "Library"
   - Busca y habilita las siguientes APIs:
     - Maps JavaScript API
     - Geocoding API
     - Places API
     - Directions API
     - Routes API (para optimización de rutas)

### Paso 4: Crear credenciales API

1. **Crear clave de API**
   - Ve a "APIs & Services" > "Credentials"
   - Haz clic en "Create Credentials" > "API Key"
   - Copia la clave generada

2. **Restringir la clave de API**
   - Haz clic en la clave creada para editarla
   - En "Application restrictions", selecciona "HTTP referrers"
   - Agrega los dominios de tu aplicación
   - En "API restrictions", selecciona "Restrict key"
   - Selecciona solo las APIs que necesitas

3. **Configurar cuotas y límites**
   - Ve a "APIs & Services" > "Quotas"
   - Configura límites diarios para cada API
   - Recomendado: 1000 requests por día para empezar

## Configuración de Firebase Messaging

### ¿Por qué necesitas Firebase?

Firebase Messaging te permite enviar notificaciones push a los usuarios de tu aplicación, como:
- Notificaciones de nuevos pedidos
- Actualizaciones de estado de entrega
- Recordatorios importantes

### Paso 1: Migración del proyecto Firebase

**IMPORTANTE**: Una vez que hayas configurado la facturación en Google Cloud, nuestro equipo migrará el proyecto Firebase completo a tu cuenta.

1. **Proceso de migración**
   - Te enviaremos una invitación por correo electrónico a tu cuenta de Google
   - Acepta la invitación cuando la recibas
   - El proyecto Firebase se transferirá automáticamente a tu cuenta

2. **Lo que incluye la migración**
   - Proyecto Firebase completo con todas las configuraciones
   - Configuración de Cloud Messaging
   - Archivos de configuración para Android e iOS
   - Configuración de notificaciones push
   - Todas las credenciales y claves necesarias

3. **Después de la migración**
   - Tendrás control total sobre el proyecto Firebase (Firebase Messaging)
   - Podrás ver el uso y costos en tu cuenta

## Configuración de VPS

### ¿Qué es un VPS y por qué lo necesitas?

Un VPS (Virtual Private Server) es un servidor virtual que te permite:
- Alojar tu backend Laravel
- Ejecutar bases de datos
- Configurar servicios de email
- Tener control total sobre el servidor

### Características recomendadas para el servidor

- **CPU**: 2 vCPUs (núcleos virtuales)
- **RAM**: 4 GB
- **Almacenamiento**: 50 GB SSD
- **Transferencia**: Mínimo 2 TB por mes
- **Ubicación**: Preferiblemente en Estados Unidos

## Comparativa de Proveedores VPS

### Opciones Recomendadas

| Proveedor | Plan | Precio Mensual | Almacenamiento | Transferencia | Ubicación | Ventajas |
|-----------|------|----------------|----------------|---------------|-----------|----------|
| **Hostinger** | VPS 2 vCPU/4GB | $6.99 | 50 GB SSD | 4 TB | Estados Unidos | Soporte en español, panel intuitivo |
| **Gospel iDEA** | VPS 2 vCPU/4GB | $24.99 | 60 GB NVMe | 2 TB | Perú | Soporte 24/7 en español, activación inmediata |
| **Contabo** | VPS 10 | €4.50 (~$5) | 300 GB SSD | 32 TB | Alemania | Excelente relación calidad-precio |
| **LumaDock** | 4 vCPU/4GB | $4.99 | 50 GB NVMe | Ilimitado | Europa | Sin contrato mínimo |

### Recomendación por Presupuesto

**Presupuesto Bajo ($5-10/mes)**
- Contabo: Mejor opción por precio y almacenamiento
- LumaDock: Buena opción con transferencia ilimitada

**Presupuesto Medio ($15-25/mes)**
- Hostinger: Excelente para iniciar
- Gospel iDEA: Ideal si necesitas soporte en español

**Presupuesto Alto ($25+/mes)**
- HostRound: Mayor transferencia mensual

## Instalación del Backend

### ¿Qué necesitas hacer después de contratar el VPS?

Una vez que hayas contratado tu VPS con las especificaciones recomendadas, **nuestro equipo técnico se encargará de toda la instalación y configuración del servidor**. No necesitas conocimientos de programación.

### Lo que incluye nuestra instalación:

- **Configuración completa del servidor** (Ubuntu, Nginx, PHP, MySQL)
- **Instalación del backend Laravel** de MedRush
- **Configuración de la base de datos**
- **Configuración de SSL** para seguridad
- **Configuración de dominio** y subdominios

### Información que necesitamos de ti:

1. **Datos de acceso al VPS** (IP, usuario, contraseña)
2. **Dominio principal** (ej: medrush.com)
3. **Claves de Google Cloud** (configuradas en pasos anteriores)
4. **Correo electrónico de Google** (para enviar invitación de Firebase)
5. **Confirmación de facturación** (que hayas configurado la facturación en Google Cloud)

### Tiempo estimado de instalación:

- **Configuración inicial**: 2-4 horas
- **Pruebas y optimización**: 1-2 horas
- **Total**: 1 día hábil

**Nota**: Una vez instalado, tu aplicación estará lista para usar y nuestro equipo te proporcionará toda la documentación necesaria para el mantenimiento básico.

## Consideraciones de Costos

### Google Cloud Platform
- **Créditos gratuitos**: $300 USD por 90 días
- **Costo estimado mensual**: $10-50 USD (dependiendo del uso)

> **Fuente oficial**: Los precios mostrados están basados en la [documentación oficial de precios de Google Maps Platform](https://developers.google.com/maps/billing-and-pricing/pricing?hl=es-419#routes-pricing). Los costos pueden variar según el volumen de uso y las promociones disponibles.

#### Monitoreo de costos en la aplicación:
- **Panel de administración**: Visualización en tiempo real del uso de APIs
- **Alertas automáticas**: Notificaciones cuando se acerque a los límites
- **Reportes detallados**: Desglose por servicio y período
- **Control de gastos**: Límites configurables por API

### Firebase Messaging
- **Costo**: Gratuito hasta 10,000 notificaciones por mes
- **Costo adicional**: $0.40 por cada 1,000 notificaciones extra

### VPS
- **Costo mensual**: $5-25 USD
- **Costo anual**: $60-300 USD
- **Ahorro**: Algunos proveedores ofrecen descuentos por pago anual

### Total Estimado Mensual
- **Mínimo**: $15-20 USD/mes (uso básico)
- **Promedio**: $25-40 USD/mes (uso moderado)
- **Alto uso**: $150-200 USD/mes (uso intensivo con todas las APIs)

## Preguntas Frecuentes

### ¿Puedo usar solo Google Cloud sin VPS?
No, necesitas un VPS para alojar tu servidor (backend Laravel). Google Cloud solo proporciona las APIs (Servicios) de mapas. Nuestro equipo se encarga de la instalación del backend en tu VPS.

### ¿Qué pasa si excedo los límites de Google Cloud?
Google te cobrará automáticamente por el uso excedente. Configure alertas de facturación para evitar sorpresas.

### ¿Puedo cambiar de proveedor VPS después?
Sí, pero requiere migración de datos. Nuestro equipo puede ayudarte con la migración si es necesario.

### ¿Necesito conocimientos técnicos avanzados?
No, nuestro equipo se encarga de toda la instalación técnica. Solo necesitas configurar las cuentas de Google Cloud y Firebase siguiendo esta guía.

### ¿Cómo funciona la migración de Firebase?
Te enviaremos una invitación por correo electrónico a tu cuenta de Google. Al aceptar la invitación, el proyecto Firebase se transferirá automáticamente a tu cuenta, incluyendo todas las configuraciones y credenciales necesarias.
