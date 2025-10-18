<?php

namespace App\Policies;

use App\Models\PerfilRepartidor;
use App\Models\User;

class PerfilRepartidorPolicy
{
  public function viewAny(User $user): bool
  {
    return $user->esAdmin();
  }

  public function view(User $user, PerfilRepartidor $perfilRepartidor): bool
  {
    if ($user->esAdmin()) {
      return true;
    }

    return $user->id === $perfilRepartidor->id;
  }

  public function register(User $user): bool
  {
    return $user->esAdmin();
  }

  public function update(User $user, PerfilRepartidor $perfilRepartidor): bool
  {
    if ($user->esAdmin()) {
      return true;
    }

    return $user->id === $perfilRepartidor->id;
  }

  public function updateVerificado(User $user, PerfilRepartidor $perfilRepartidor): bool
  {
    return $user->esAdmin();
  }

  public function updateEstado(User $user, PerfilRepartidor $perfilRepartidor): bool
  {
    return $user->id === $perfilRepartidor->id;
  }

  public function delete(User $user, PerfilRepartidor $perfilRepartidor): bool
  {
    return $user->esAdmin();
  }
}
