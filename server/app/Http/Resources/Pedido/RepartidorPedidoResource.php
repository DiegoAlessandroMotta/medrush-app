<?php

namespace App\Http\Resources\Pedido;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RepartidorPedidoResource extends JsonResource
{
  public static $relationName = 'repartidor';

  public function toArray(Request $request): array
  {
    return [
      'id' => $this->id,
      'verificado' => $this->verificado,
      'nombre' => $this->whenLoaded('user', fn() => $this->user->name),
    ];
  }
}
