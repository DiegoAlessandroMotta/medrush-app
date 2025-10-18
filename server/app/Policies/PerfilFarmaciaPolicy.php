<?php

namespace App\Policies;

use App\Models\PerfilFarmacia;
use App\Models\User;

class PerfilFarmaciaPolicy
{
  public function viewAny(User $user): bool
  {
    return $user->esAdmin() || $user->esFarmacia();
  }

  public function view(User $user, PerfilFarmacia $perfilFarmacia): bool
  {
    if ($user->esAdmin()) {
      return true;
    }

    if (
      $user->esFarmacia()
      && $user->perfilFarmacia?->farmacia_id === $perfilFarmacia->farmacia_id
    ) {
      return true;
    }

    return false;
  }

  public function register(User $user): bool
  {
    return $user->esAdmin();
  }

  public function update(User $user, PerfilFarmacia $perfilFarmacia): bool
  {
    if ($user->esAdmin()) {
      return true;
    }

    if (
      $user->esFarmacia()
      && $user->id === $perfilFarmacia->id
    ) {
      return true;
    }

    return false;
  }

  public function delete(User $user, PerfilFarmacia $perfilFarmacia): bool
  {
    return $user->esAdmin();
  }
}
