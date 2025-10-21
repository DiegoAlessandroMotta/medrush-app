<?php

namespace App\Policies;

use App\Models\ReportePdf;
use App\Models\User;

class ReportePdfPolicy
{
  public function viewAny(User $user): bool
  {
    return true;
  }

  public function view(User $user, ReportePdf $reportePdf): bool
  {
    return true;
  }

  public function delete(User $user, ReportePdf $reportePdf): bool
  {
    return $user->esAdmin() || $reportePdf->user_id === $user->id;
  }

  public function deleteAntiguos(User $user): bool
  {
    return $user->esAdmin();
  }

  public function regenerar(User $user, ReportePdf $reportePdf): bool
  {
    return true;
  }

  public function createEtiquetasPedido(User $user): bool
  {
    return true;
  }
}
