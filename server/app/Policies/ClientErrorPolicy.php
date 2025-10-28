<?php

namespace App\Policies;

use App\Models\ClientError;
use App\Models\User;

class ClientErrorPolicy
{
  public function viewAny(User $user): bool
  {
    return $user->esAdmin();
  }

  public function create(User $user): bool
  {
    return true;
  }
}
