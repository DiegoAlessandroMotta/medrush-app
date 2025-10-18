<?php

namespace App\Http\Resources\Ruta;

use App\Http\Resources\Pedido\RepartidorPedidoResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RutaSimpleResource extends JsonResource
{
  public function toArray(Request $request): array
  {
    return [
      'id' => $this->id,
      // 'repartidor_id' => $this->repartidor_id,
      'nombre' => $this->nombre,
      // 'punto_inicio' => AsPoint::serializeValue($this->punto_inicio),
      // 'punto_final' => AsPoint::serializeValue($this->punto_final),
      'distancia_total_estimada' => $this->distancia_total_estimada,
      'tiempo_total_estimado' => $this->tiempo_total_estimado,
      'cantidad_pedidos' => $this->cantidad_pedidos,
      'fecha_hora_calculo' => $this->fecha_hora_calculo,
      'fecha_inicio' => $this->fecha_inicio,
      'fecha_completado' => $this->fecha_completado,
      'created_at' => $this->created_at,
      'updated_at' => $this->updated_at,
      'repartidor' => $this->whenLoaded(RepartidorPedidoResource::$relationName, fn() => new RepartidorPedidoResource($this->repartidor)),
    ];
  }
}
