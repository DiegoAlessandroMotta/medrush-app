<?php

namespace App\Policies;

use App\Enums\RolesEnum;
use App\Models\User;

class GoogleApiServicePolicy
{
  public function reverseGeocode(User $user): bool
  {
    return $user->hasAnyRole([RolesEnum::ADMINISTRADOR, RolesEnum::REPARTIDOR]);
  }

  public function getDirectionsWithWaypoints(User $user): bool
  {
    return $user->hasAnyRole([RolesEnum::ADMINISTRADOR, RolesEnum::REPARTIDOR]);
  }

  public function getRouteInfo(User $user): bool
  {
    return $user->hasAnyRole([RolesEnum::ADMINISTRADOR, RolesEnum::REPARTIDOR]);
  }
}
