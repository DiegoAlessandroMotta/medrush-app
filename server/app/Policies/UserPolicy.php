<?php

namespace App\Policies;

use App\Models\User;

class UserPolicy
{
  public function viewAny(User $user): bool
  {
    return $user->esAdmin();
  }

  public function view(User $user, User $model): bool
  {
    return $user->esAdmin();
  }

  public function register(User $user): bool
  {
    return $user->esAdmin();
  }

  public function update(User $user, User $model): bool
  {
    if ($user->esAdmin() && $user->id === $model->id) {
      return true;
    }

    return false;
  }

  public function uploadPicture(User $user, User $model)
  {
    if ($user->esAdmin()) {
      return true;
    }

    return $user->id === $model->id;
  }

  public function updateActivo(User $user)
  {
    return $user->esAdmin();
  }

  public function delete(User $user, User $model): bool
  {
    return $user->esAdmin();
  }
}
