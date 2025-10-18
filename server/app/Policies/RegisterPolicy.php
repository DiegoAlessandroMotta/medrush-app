<?php

namespace App\Policies;

use App\Enums\PermissionsEnum;
use App\Enums\RolesEnum;
use App\Models\User;

class RegisterPolicy
{
  public function registerAdminUser(User $user)
  {
    return $user->hasRole(RolesEnum::ADMINISTRADOR);
  }

  public function registerRepartidorUser(User $user)
  {
    return $user->hasRole(RolesEnum::ADMINISTRADOR);
  }

  public function registerFarmaciaUser(User $user)
  {
    return $user->hasPermissionTo(PermissionsEnum::FARMACIAS_CREATE_ANY);
  }
}
