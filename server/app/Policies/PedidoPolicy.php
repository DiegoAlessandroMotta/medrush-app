<?php

namespace App\Policies;

use App\Enums\EstadosPedidoEnum;
use App\Enums\PermissionsEnum;
use App\Models\Pedido;
use App\Models\User;

class PedidoPolicy
{
  public function viewAny(User $user): bool
  {
    return $user->hasAnyPermission([PermissionsEnum::PEDIDOS_VIEW_ANY, PermissionsEnum::PEDIDOS_VIEW_RELATED]);
  }

  public function view(User $user, Pedido $pedido): bool
  {
    if ($user->hasPermissionTo(PermissionsEnum::PEDIDOS_VIEW_ANY)) {
      return true;
    }

    if (
      $user->esRepartidor()
      && $pedido->estado === EstadosPedidoEnum::PENDIENTE
    ) {
      return true;
    }

    if (
      $user->hasPermissionTo(PermissionsEnum::PEDIDOS_VIEW_RELATED)
      && ($pedido->repartidor_id === $user->id
        || $user->perfilFarmacia?->farmacia_id === $pedido->farmacia_id)
    ) {
      return true;
    }

    return false;
  }

  public function create(User $user): bool
  {
    return $user->hasAnyPermission([PermissionsEnum::PEDIDOS_CREATE_ANY, PermissionsEnum::PEDIDOS_CREATE_RELATED]);
  }

  public function createFromCsv(User $user): bool
  {
    return $user->hasAnyPermission([PermissionsEnum::PEDIDOS_CREATE_ANY, PermissionsEnum::PEDIDOS_CREATE_RELATED]);
  }

  public function update(User $user, Pedido $pedido): bool
  {
    if ($user->hasPermissionTo(PermissionsEnum::PEDIDOS_UPDATE_ANY)) {
      return true;
    }

    if (
      $user->hasPermissionTo(PermissionsEnum::PEDIDOS_UPDATE_RELATED)
      && $user->perfilFarmacia?->farmacia_id === $pedido->farmacia_id
    ) {
      return true;
    }

    return false;
  }

  public function delete(User $user, Pedido $pedido): bool
  {
    return $user->hasPermissionTo(PermissionsEnum::PEDIDOS_DELETE_ANY);
  }

  public function asignar(User $user, Pedido $pedido): bool
  {
    if ($user->esAdmin() || $user->esRepartidor()) {
      return true;
    }

    return false;
  }

  public function retirarRepartidor(User $user, Pedido $pedido): bool
  {
    if ($user->esAdmin() || $user->esRepartidor()) {
      return true;
    }

    return false;
  }

  public function cancelar(User $user, Pedido $pedido): bool
  {
    if ($user->esAdmin()) {
      return true;
    }

    if (
      $user->esFarmacia()
      && $user->perfilFarmacia?->farmacia_id === $pedido->farmacia_id
    ) {
      return true;
    }

    return false;
  }

  public function recoger(User $user, Pedido $pedido): bool
  {
    if (
      $user->esRepartidor()
      && $user->id === $pedido->repartidor_id
    ) {
      return true;
    }

    return false;
  }

  public function enRuta(User $user, Pedido $pedido): bool
  {
    if (
      $user->esRepartidor()
      && $user->id === $pedido->repartidor_id
    ) {
      return true;
    }

    return false;
  }

  public function entregar(User $user, Pedido $pedido): bool
  {
    if (
      $user->esRepartidor()
      && $user->id === $pedido->repartidor_id
    ) {
      return true;
    }

    return false;
  }

  public function falloEntrega(User $user, Pedido $pedido): bool
  {
    if ($user->esAdmin()) {
      return true;
    }

    if (
      $user->esRepartidor()
      && $user->id === $pedido->repartidor_id
    ) {
      return true;
    }

    return false;
  }
}
