<?php

namespace App\Policies;

use App\Models\User;

class GoogleApiUsagePolicy
{
  public function viewUsageStats(User $user): bool
  {
    return $user->esAdmin();
  }
}
