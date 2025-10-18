<?php

namespace App\Http\Controllers;

use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Requests\Notificacion\IndexNotificacionRequest;
use Illuminate\Notifications\DatabaseNotification;
use Auth;

class NotificationController extends Controller
{
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

  public function markAllAsRead()
  {
    $user = Auth::user();

    $updatedCount = $user->unreadNotifications()->update(['read_at' => now()]);

    return ApiResponder::success(
      message: "Se marcaron $updatedCount notificaciones como leídas",
      data: ['updated_count' => $updatedCount],
    );
  }

  public function getUnreadCount()
  {
    $user = Auth::user();

    $unreadCount = $user->unreadNotifications()->count();

    return ApiResponder::success(
      message: 'Conteo de notificaciones no leídas obtenido',
      data: ['unread_count' => $unreadCount],
    );
  }

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
