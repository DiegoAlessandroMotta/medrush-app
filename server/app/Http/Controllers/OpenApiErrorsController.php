<?php

namespace App\Http\Controllers;

/**
 * OpenAPI Error Responses Components
 *
 * Componentes genéricos reutilizables para respuestas de error HTTP.
 * Estos se usan en las anotaciones @OA\ de los controladores.
 *
 * @OA\Schema(
 *     schema="Error",
 *     type="object",
 *     description="Estructura base de error en la respuesta",
 *     @OA\Property(
 *         property="code",
 *         type="string",
 *         description="Código de error único",
 *         example="VALIDATION_ERROR"
 *     ),
 *     @OA\Property(
 *         property="errors",
 *         type="object",
 *         description="Mapa de errores por campo (opcional)",
 *         nullable=true,
 *         additionalProperties=true,
 *         example={"email": {"Las credenciales proporcionadas son incorrectas."}}
 *     )
 * )
 *
 * @OA\Schema(
 *     schema="BadRequestResponse",
 *     type="object",
 *     description="Respuesta 400 - Solicitud malformada",
 *     @OA\Property(property="status", type="string", enum={"fail"}, example="fail"),
 *     @OA\Property(property="message", type="string", example="La solicitud no pudo ser procesada debido a una sintaxis inválida o datos incorrectos."),
 *     @OA\Property(property="error", ref="#/components/schemas/Error"),
 * )
 *
 * @OA\Schema(
 *     schema="UnauthorizedResponse",
 *     type="object",
 *     description="Respuesta 401 - No autenticado",
 *     @OA\Property(property="status", type="string", enum={"fail"}, example="fail"),
 *     @OA\Property(property="message", type="string", example="No autenticado. Por favor, inicie sesión."),
 *     @OA\Property(property="error", type="object",
 *         @OA\Property(property="code", type="string", enum={"UNAUTHORIZED"}, example="UNAUTHORIZED"),
 *         @OA\Property(property="errors", type="null"),
 *     ),
 * )
 *
 * @OA\Schema(
 *     schema="ForbiddenResponse",
 *     type="object",
 *     description="Respuesta 403 - Acceso prohibido/No tiene permiso",
 *     @OA\Property(property="status", type="string", enum={"fail"}, example="fail"),
 *     @OA\Property(property="message", type="string", example="No tiene permiso para realizar esta acción."),
 *     @OA\Property(property="error", type="object",
 *         @OA\Property(property="code", type="string", enum={"FORBIDDEN"}, example="FORBIDDEN"),
 *         @OA\Property(property="errors", type="null"),
 *     ),
 * )
 *
 * @OA\Schema(
 *     schema="NotFoundResponse",
 *     type="object",
 *     description="Respuesta 404 - Recurso no encontrado",
 *     @OA\Property(property="status", type="string", enum={"fail"}, example="fail"),
 *     @OA\Property(property="message", type="string", example="El recurso solicitado no fue encontrado."),
 *     @OA\Property(property="error", type="object",
 *         @OA\Property(property="code", type="string", enum={"NOT_FOUND"}, example="NOT_FOUND"),
 *         @OA\Property(property="errors", type="null"),
 *     ),
 * )
 *
 * @OA\Schema(
 *     schema="ValidationErrorResponse",
 *     type="object",
 *     description="Respuesta 422 - Error de validación en los datos",
 *     @OA\Property(property="status", type="string", enum={"fail"}, example="fail"),
 *     @OA\Property(property="message", type="string", example="Los datos proporcionados no son válidos."),
 *     @OA\Property(property="error", type="object",
 *         @OA\Property(property="code", type="string", enum={"VALIDATION_ERROR"}, example="VALIDATION_ERROR"),
 *         @OA\Property(property="errors", type="object",
 *             description="Errores de validación por campo",
 *             additionalProperties=true,
 *             example={"email": {"Email es requerido"}, "password": {"Password debe tener al menos 8 caracteres"}}
 *         ),
 *     ),
 * )
 *
 * @OA\Schema(
 *     schema="MethodNotAllowedResponse",
 *     type="object",
 *     description="Respuesta 405 - Método HTTP no permitido",
 *     @OA\Property(property="status", type="string", enum={"fail"}, example="fail"),
 *     @OA\Property(property="message", type="string", example="Método HTTP no permitido para esta ruta."),
 *     @OA\Property(property="error", type="object",
 *         @OA\Property(property="code", type="string", enum={"METHOD_NOT_ALLOWED"}, example="METHOD_NOT_ALLOWED"),
 *         @OA\Property(property="errors", type="null"),
 *     ),
 * )
 *
 * @OA\Schema(
 *     schema="InvalidSignatureResponse",
 *     type="object",
 *     description="Respuesta 403 - Enlace de descarga inválido o expirado",
 *     @OA\Property(property="status", type="string", enum={"fail"}, example="fail"),
 *     @OA\Property(property="message", type="string", example="El enlace de descarga es inválido o ha expirado. Por favor, solicite uno nuevo."),
 *     @OA\Property(property="error", type="object",
 *         @OA\Property(property="code", type="string", enum={"INVALID_SIGNED_URL"}, example="INVALID_SIGNED_URL"),
 *         @OA\Property(property="errors", type="null"),
 *     ),
 * )
 *
 * @OA\Schema(
 *     schema="ServerErrorResponse",
 *     type="object",
 *     description="Respuesta 500 - Error interno del servidor",
 *     @OA\Property(property="status", type="string", enum={"error"}, example="error"),
 *     @OA\Property(property="message", type="string", example="Error interno del servidor."),
 *     @OA\Property(property="error", type="object",
 *         @OA\Property(property="code", type="string", enum={"SERVER_ERROR"}, example="SERVER_ERROR"),
 *         @OA\Property(property="errors", type="null"),
 *     ),
 * )
 *
 * @OA\Schema(
 *     schema="SuccessResponse",
 *     type="object",
 *     description="Estructura genérica de respuesta exitosa",
 *     @OA\Property(property="status", type="string", enum={"success"}, example="success"),
 *     @OA\Property(property="message", type="string", example="Operación completada exitosamente."),
 *     @OA\Property(property="data", type="object", nullable=true, description="Datos de la respuesta"),
 *     @OA\Property(property="pagination", type="object", nullable=true, description="Información de paginación"),
 *     @OA\Property(property="cursor_pagination", type="object", nullable=true, description="Información de paginación por cursor"),
 *     @OA\Property(property="metadata", type="object", nullable=true, description="Metadatos adicionales"),
 * )
 *
 * @OA\Schema(
 *     schema="PaginationInfo",
 *     type="object",
 *     description="Información de paginación",
 *     @OA\Property(property="total", type="integer", example=100),
 *     @OA\Property(property="count", type="integer", example=10),
 *     @OA\Property(property="per_page", type="integer", example=10),
 *     @OA\Property(property="current_page", type="integer", example=1),
 *     @OA\Property(property="total_pages", type="integer", example=10),
 *     @OA\Property(property="links", type="object",
 *         @OA\Property(property="first", type="string", format="url", nullable=true),
 *         @OA\Property(property="last", type="string", format="url", nullable=true),
 *         @OA\Property(property="next", type="string", format="url", nullable=true),
 *         @OA\Property(property="prev", type="string", format="url", nullable=true),
 *     ),
 * )
 *
 * @OA\Schema(
 *     schema="CursorPaginationInfo",
 *     type="object",
 *     description="Información de paginación por cursor",
 *     @OA\Property(property="next_cursor", type="string", nullable=true),
 *     @OA\Property(property="prev_cursor", type="string", nullable=true),
 *     @OA\Property(property="path", type="string", format="url"),
 *     @OA\Property(property="per_page", type="integer"),
 * )
 */
class OpenApiErrorsController extends Controller {}
