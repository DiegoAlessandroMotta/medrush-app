<?php

namespace App\Policies;

use App\Enums\RolesEnum;
use App\Models\User;

class BaseUserPolicy
{
  public function uploadPicture(User $authUser, User $user)
  {
    if ($user->esAdmin()) {
      return true;
    }

    return $authUser->id === $user->id;
  }

  public function activo(User $authUser)
  {
    return $authUser->esAdmin();
  }
}
