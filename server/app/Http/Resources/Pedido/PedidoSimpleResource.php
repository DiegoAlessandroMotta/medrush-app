<?php

namespace App\Http\Resources\Pedido;

use App\Casts\AsPoint;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PedidoSimpleResource extends JsonResource
{
  public function toArray(Request $request): array
  {
    $ubicacionEntrega = AsPoint::serializeValue($this->ubicacion_entrega);

    return [
      'id' => $this->id,
      'codigo_barra' => $this->codigo_barra,
      'paciente_nombre' => $this->paciente_nombre,
      'paciente_telefono' => $this->paciente_telefono,
      'direccion_entrega_linea_1' => $this->direccion_entrega_linea_1,
      'ciudad_entrega' => $this->ciudad_entrega,
      'estado_region_entrega' => $this->estado_region_entrega,
      'ubicacion_entrega' => $ubicacionEntrega,
      'estado' => $this->estado,
      'fecha_asignacion' => $this->fecha_asignacion,
      'fecha_recogida' => $this->fecha_recogida,
      'fecha_entrega' => $this->fecha_entrega,
      'created_at' => $this->created_at,
      'updated_at' => $this->updated_at,
      // 'farmacia' => $this->whenLoaded('farmacia', fn() => [
      //   'id' => $this->farmacia->id,
      //   'nombre' => $this->farmacia->nombre,
      // ]),
      'repartidor' => $this->whenLoaded(RepartidorPedidoResource::$relationName, fn() => new RepartidorPedidoResource($this->repartidor)),
    ];
  }
}
