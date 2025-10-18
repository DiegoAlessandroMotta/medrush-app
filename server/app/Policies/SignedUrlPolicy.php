<?php

namespace App\Policies;

use App\Models\User;

class SignedUrlPolicy
{
  public function getSignedUrlCsvTemplate(User $user): bool
  {
    if ($user->esAdmin() || $user->esFarmacia()) {
      return true;
    }

    return false;
  }
}
