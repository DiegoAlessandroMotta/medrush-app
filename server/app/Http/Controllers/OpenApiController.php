<?php

namespace App\Http\Controllers;

/**
 * @OA\Info(
 *     version="1.0.0",
 *     title="MedRushApp API",
 *     description="API REST para el sistema de distribución de medicinas MedRush",
 *     termsOfService="https://example.com/terms",
 *     contact=@OA\Contact(
 *         email="support@example.com",
 *         name="API Support",
 *         url="https://example.com/support"
 *     ),
 *     license=@OA\License(
 *         name="MIT",
 *         url="https://opensource.org/licenses/MIT"
 *     )
 * )
 *
 * @OA\Server(
 *     url="http://localhost:4000",
 *     description="Servidor Local"
 * )
 *
 * @OA\Server(
 *     url="https://api.medrush.com",
 *     description="Servidor de Producción"
 * )
 *
 * @OA\SecurityScheme(
 *     type="http",
 *     description="Token de acceso Sanctum. Se obtiene en el endpoint de login.",
 *     name="Token based based auth",
 *     in="header",
 *     scheme="bearer",
 *     bearerFormat="Sanctum",
 *     securityScheme="sanctum"
 * )
 *
 * @OA\Tag(
 *     name="Auth",
 *     description="Endpoints de autenticación y gestión de sesiones"
 * )
 *
 * @OA\Tag(
 *     name="Users",
 *     description="Endpoints para gestión de usuarios, repartidores y farmacias"
 * )
 *
 * @OA\Tag(
 *     name="PerfilBase",
 *     description="Endpoints para usuarios base"
 * )
 *
 * @OA\Tag(
 *     name="PerfilAdministrador",
 *     description="Endpoints para administradores del sistema"
 * )
 *
 * @OA\Tag(
 *     name="PerfilFarmacia",
 *     description="Endpoints para usuarios de farmacias"
 * )
 *
 * @OA\Tag(
 *     name="PerfilRepartidor",
 *     description="Endpoints para usuarios repartidores"
 * )
 *
 * @OA\Tag(
 *     name="Pedidos",
 *     description="Endpoints para gestión de pedidos"
 * )
 *
 * @OA\Tag(
 *     name="Eventos",
 *     description="Endpoints para gestión de eventos de pedidos"
 * )
 *
 * @OA\Tag(
 *     name="Farmacias",
 *     description="Endpoints para gestión de farmacias"
 * )
 *
 * @OA\Tag(
 *     name="Rutas",
 *     description="Endpoints para gestión de rutas de entrega"
 * )
 *
 * @OA\Tag(
 *     name="Entities",
 *     description="Endpoints para gestión de entidades relacionadas"
 * )
 *
 * @OA\Tag(
 *     name="Reportes",
 *     description="Endpoints para generación de reportes"
 * )
 *
 * @OA\Tag(
 *     name="Maps",
 *     description="Endpoints para servicios de mapas y geolocalización"
 * )
 *
 * @OA\Tag(
 *     name="Notifications",
 *     description="Endpoints para gestión de notificaciones"
 * )
 *
 * @OA\Tag(
 *     name="FCM",
 *     description="Endpoints para gestión de tokens FCM (Firebase Cloud Messaging)"
 * )
 *
 * @OA\Tag(
 *     name="Downloads",
 *     description="Endpoints para descargas de archivos"
 * )
 */
class OpenApiController extends Controller {}
