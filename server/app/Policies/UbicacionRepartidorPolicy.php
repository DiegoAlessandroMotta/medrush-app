<?php

namespace App\Policies;

use App\Models\User;

class UbicacionRepartidorPolicy
{
  public function viewAny(User $user): bool
  {
    return $user->esAdmin() || $user->esRepartidor();
  }

  public function create(User $user): bool
  {
    return $user->esRepartidor();
  }
}
