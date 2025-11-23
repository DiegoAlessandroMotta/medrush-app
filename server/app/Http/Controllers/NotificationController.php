<?php

namespace App\Http\Controllers;

use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Requests\Notificacion\IndexNotificacionRequest;
use Illuminate\Notifications\DatabaseNotification;
use Auth;

class NotificationController extends Controller
{
  /**
   * @OA\Get(
   *     path="/api/notifications",
   *     operationId="notificationsIndex",
   *     tags={"Notifications"},
   *     summary="Listar notificaciones",
   *     description="Obtiene una lista paginada de notificaciones del usuario autenticado. Puede filtrar solo no leídas y por tipo de notificación.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="page",
   *         in="query",
   *         required=false,
   *         description="Número de página (por defecto: 1)",
   *         @OA\Schema(type="integer", example=1),
   *     ),
   *     @OA\Parameter(
   *         name="per_page",
   *         in="query",
   *         required=false,
   *         description="Cantidad de elementos por página (por defecto: 15)",
   *         @OA\Schema(type="integer", example=15),
   *     ),
   *     @OA\Parameter(
   *         name="order_by",
   *         in="query",
   *         required=false,
   *         description="Campo por el que ordenar (created_at, updated_at)",
   *         @OA\Schema(type="string", example="created_at"),
   *     ),
   *     @OA\Parameter(
   *         name="order_direction",
   *         in="query",
   *         required=false,
   *         description="Dirección del ordenamiento (asc, desc)",
   *         @OA\Schema(type="string", enum={"asc", "desc"}, example="desc"),
   *     ),
   *     @OA\Parameter(
   *         name="unread_only",
   *         in="query",
   *         required=false,
   *         description="Mostrar solo notificaciones no leídas (true, false)",
   *         @OA\Schema(type="boolean", example=false),
   *     ),
   *     @OA\Parameter(
   *         name="type",
   *         in="query",
   *         required=false,
   *         description="Filtrar por tipo de notificación (ej: App\Notifications\PedidoCreado)",
   *         @OA\Schema(type="string", example="App\Notifications\PedidoCreado"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Lista de notificaciones obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Lista de notificaciones obtenida exitosamente"),
   *             @OA\Property(property="data", type="array", items=@OA\Items(
   *                 type="object",
   *                 @OA\Property(property="id", type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *                 @OA\Property(property="type", type="string", example="App\Notifications\PedidoCreado"),
   *                 @OA\Property(property="notifiable_id", type="string", format="uuid", description="ID del usuario que recibe la notificación"),
   *                 @OA\Property(property="data", type="object", description="Datos específicos de la notificación"),
   *                 @OA\Property(property="read_at", type="string", format="date-time", nullable=true, example=null),
   *                 @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *             )),
   *             @OA\Property(property="pagination", type="object",
   *                 @OA\Property(property="total", type="integer", example=125),
   *                 @OA\Property(property="per_page", type="integer", example=15),
   *                 @OA\Property(property="current_page", type="integer", example=1),
   *                 @OA\Property(property="last_page", type="integer", example=9),
   *                 @OA\Property(property="from", type="integer", example=1),
   *                 @OA\Property(property="to", type="integer", example=15),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Error de validación en parámetros",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
  public function index(IndexNotificacionRequest $request)
  {
    $user = Auth::user();

    $perPage = $request->getPerPage();
    $currentPage = $request->getCurrentPage();
    $orderBy = $request->getOrderBy();
    $orderDirection = $request->getOrderDirection();

    $query = $user->notifications();

    if ($request->hasUnreadOnly() && $request->getUnreadOnly()) {
      $query->whereNull('read_at');
    }

    if ($request->hasType()) {
      $query->where('type', $request->getType());
    }

    $query->orderBy($orderBy, $orderDirection);

    $notifications = $query->paginate(
      perPage: $perPage,
      page: $currentPage,
    );

    return ApiResponder::success(
      message: 'Lista de notificaciones obtenida exitosamente',
      data: $notifications->items(),
      pagination: $notifications,
    );
  }

  /**
   * @OA\Get(
   *     path="/api/notifications/{notificationId}",
   *     operationId="notificationsShow",
   *     tags={"Notifications"},
   *     summary="Obtener detalles de una notificación",
   *     description="Retorna la información completa de una notificación específica. Solo el usuario puede ver sus propias notificaciones.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="notificationId",
   *         in="path",
   *         required=true,
   *         description="UUID de la notificación",
   *         @OA\Schema(type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Notificación obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Notificación obtenida exitosamente"),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid"),
   *                 @OA\Property(property="type", type="string", example="App\Notifications\PedidoCreado"),
   *                 @OA\Property(property="notifiable_id", type="string", format="uuid"),
   *                 @OA\Property(property="data", type="object"),
   *                 @OA\Property(property="read_at", type="string", format="date-time", nullable=true),
   *                 @OA\Property(property="created_at", type="string", format="date-time"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time"),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Notificación no encontrada o no pertenece al usuario",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   * )
   */
  public function show(DatabaseNotification $notification)
  {
    $user = Auth::user();

    if ($notification->notifiable_id !== $user->id) {
      throw CustomException::notFound();
    }

    return ApiResponder::success(
      message: 'Notificación obtenida exitosamente',
      data: $notification,
    );
  }

  /**
   * @OA\Patch(
   *     path="/api/notifications/{notificationId}/marcar-leida",
   *     operationId="notificationsMarkAsRead",
   *     tags={"Notifications"},
   *     summary="Marcar notificación como leída",
   *     description="Marca una notificación específica como leída. Si ya estaba leída, no hace cambios.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="notificationId",
   *         in="path",
   *         required=true,
   *         description="UUID de la notificación",
   *         @OA\Schema(type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Notificación marcada como leída",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Notificación marcada como leída"),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid"),
   *                 @OA\Property(property="type", type="string"),
   *                 @OA\Property(property="read_at", type="string", format="date-time", description="Fecha/hora cuando se marcó como leída"),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Notificación no encontrada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   * )
   */
  public function markAsRead(DatabaseNotification $notification)
  {
    $user = Auth::user();

    if ($notification->notifiable_id !== $user->id) {
      throw CustomException::notFound();
    }

    if (!$notification->read_at) {
      $notification->markAsRead();
    }

    return ApiResponder::success(
      message: 'Notificación marcada como leída',
      data: $notification->fresh(),
    );
  }

  /**
   * @OA\Patch(
   *     path="/api/notifications/marcar-todas-leidas",
   *     operationId="notificationsMarkAllAsRead",
   *     tags={"Notifications"},
   *     summary="Marcar todas las notificaciones como leídas",
   *     description="Marca todas las notificaciones no leídas del usuario como leídas de una sola vez.",
   *     security={{"sanctum":{}}},
   *     @OA\Response(
   *         response=200,
   *         description="Todas las notificaciones marcadas como leídas",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Se marcaron 5 notificaciones como leídas"),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="updated_count", type="integer", description="Cantidad de notificaciones actualizadas", example=5),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   * )
   */
  public function markAllAsRead()
  {
    $user = Auth::user();

    $updatedCount = $user->unreadNotifications()->update(['read_at' => now()]);

    return ApiResponder::success(
      message: "Se marcaron $updatedCount notificaciones como leídas",
      data: ['updated_count' => $updatedCount],
    );
  }

  /**
   * @OA\Get(
   *     path="/api/notifications/unread/count",
   *     operationId="notificationsGetUnreadCount",
   *     tags={"Notifications"},
   *     summary="Obtener cantidad de notificaciones no leídas",
   *     description="Retorna la cantidad de notificaciones no leídas del usuario autenticado.",
   *     security={{"sanctum":{}}},
   *     @OA\Response(
   *         response=200,
   *         description="Conteo obtenido exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Conteo de notificaciones no leídas obtenido"),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="unread_count", type="integer", example=5),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   * )
   */
  public function getUnreadCount()
  {
    $user = Auth::user();

    $unreadCount = $user->unreadNotifications()->count();

    return ApiResponder::success(
      message: 'Conteo de notificaciones no leídas obtenido',
      data: ['unread_count' => $unreadCount],
    );
  }

  /**
   * @OA\Delete(
   *     path="/api/notifications/{notificationId}",
   *     operationId="notificationsDestroy",
   *     tags={"Notifications"},
   *     summary="Eliminar una notificación",
   *     description="Elimina una notificación específica del usuario. Solo puede eliminarse notificaciones propias.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="notificationId",
   *         in="path",
   *         required=true,
   *         description="UUID de la notificación",
   *         @OA\Schema(type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Notificación eliminada exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Notificación eliminada exitosamente"),
   *             @OA\Property(property="data", type="null"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Notificación no encontrada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   * )
   */
  public function destroy(DatabaseNotification $notification)
  {
    $user = Auth::user();

    if ($notification->notifiable_id !== $user->id) {
      throw CustomException::notFound();
    }

    $notification->delete();

    return ApiResponder::success(
      message: 'Notificación eliminada exitosamente',
    );
  }

  /**
   * @OA\Delete(
   *     path="/api/notifications/limpiar-leidas",
   *     operationId="notificationsClearRead",
   *     tags={"Notifications"},
   *     summary="Eliminar todas las notificaciones leídas",
   *     description="Elimina todas las notificaciones que ya fueron leídas. Útil para mantener limpia la bandeja.",
   *     security={{"sanctum":{}}},
   *     @OA\Response(
   *         response=200,
   *         description="Notificaciones leídas eliminadas",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Se eliminaron 12 notificaciones leídas"),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="deleted_count", type="integer", description="Cantidad de notificaciones eliminadas", example=12),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   * )
   */
  public function clearRead()
  {
    $user = Auth::user();

    $deletedCount = $user->readNotifications()->delete();

    return ApiResponder::success(
      message: "Se eliminaron $deletedCount notificaciones leídas",
      data: ['deleted_count' => $deletedCount],
    );
  }
}
