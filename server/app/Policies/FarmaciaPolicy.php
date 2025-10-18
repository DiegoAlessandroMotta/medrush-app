<?php

namespace App\Policies;

use App\Enums\PermissionsEnum;
use App\Models\Farmacia;
use App\Models\User;

class FarmaciaPolicy
{
  public function viewAny(User $user): bool
  {
    return $user->hasAnyPermission([PermissionsEnum::FARMACIAS_VIEW_ANY, PermissionsEnum::FARMACIAS_VIEW_RELATED]);
  }

  public function view(User $user, Farmacia $farmacia): bool
  {
    if ($user->hasPermissionTo(PermissionsEnum::FARMACIAS_VIEW_ANY)) {
      return true;
    }

    if (
      $user->hasPermissionTo(PermissionsEnum::FARMACIAS_VIEW_RELATED)
      && $user->perfilFarmacia?->farmacia_id === $farmacia->id
    ) {
      return true;
    }

    return false;
  }

  public function create(User $user): bool
  {
    return $user->hasPermissionTo(PermissionsEnum::FARMACIAS_CREATE_ANY);
  }

  public function update(User $user, Farmacia $farmacia): bool
  {
    if ($user->hasPermissionTo(PermissionsEnum::FARMACIAS_UPDATE_ANY)) {
      return true;
    }

    if (
      $user->hasPermissionTo(PermissionsEnum::FARMACIAS_UPDATE_RELATED)
      && $user->perfilFarmacia?->farmacia_id === $farmacia->id

    ) {
      return true;
    }

    return false;
  }

  public function delete(User $user, Farmacia $farmacia): bool
  {
    return $user->hasPermissionTo(PermissionsEnum::FARMACIAS_DELETE_ANY);
  }

  public function restore(User $user, Farmacia $farmacia): bool
  {
    return false;
  }

  public function forceDelete(User $user, Farmacia $farmacia): bool
  {
    return false;
  }
}
