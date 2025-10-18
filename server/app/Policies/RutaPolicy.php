<?php

namespace App\Policies;

use App\Enums\PermissionsEnum;
use App\Models\Ruta;
use App\Models\User;

class RutaPolicy
{
  public function viewAny(User $user): bool
  {
    return $user->hasAnyPermission([PermissionsEnum::RUTAS_VIEW_ANY, PermissionsEnum::RUTAS_VIEW_RELATED]);
  }

  public function view(User $user, Ruta $ruta): bool
  {
    if ($user->hasPermissionTo(PermissionsEnum::RUTAS_VIEW_ANY)) {
      return true;
    }

    if (
      $user->hasPermissionTo(PermissionsEnum::RUTAS_VIEW_RELATED)
      && ($ruta->repartidor_id === $user->id)
    ) {
      return true;
    }

    return false;
  }

  public function create(User $user): bool
  {
    return $user->hasAnyPermission([PermissionsEnum::RUTAS_CREATE_ANY, PermissionsEnum::RUTAS_CREATE_RELATED]);
  }

  public function optimizeRutas(User $user): bool
  {
    return $user->hasPermissionTo(PermissionsEnum::RUTAS_CREATE_ANY);
  }

  public function update(User $user, Ruta $ruta): bool
  {
    if ($user->hasPermissionTo(PermissionsEnum::RUTAS_UPDATE_ANY)) {
      return true;
    }

    if (
      $user->hasPermissionTo(PermissionsEnum::RUTAS_UPDATE_RELATED)
      && $ruta->repartidor_id === $user->id
    ) {
      return true;
    }

    return false;
  }

  public function delete(User $user, Ruta $ruta): bool
  {
    if ($user->hasPermissionTo(PermissionsEnum::RUTAS_DELETE_ANY)) {
      return true;
    }

    if (
      $user->hasPermissionTo(PermissionsEnum::RUTAS_DELETE_RELATED)
      && $ruta->repartidor_id === $user->id
    ) {
      return true;
    }

    return false;
  }
}
