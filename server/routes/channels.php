<?php

use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('ubicaciones-repartidor', function (User $user) {
  return $user->esAdmin();
});

Broadcast::channel('ubicaciones-repartidor.{repartidorId}', function (User $user, string $repartidorId) {
  return $user->esAdmin();
});
