<?php

namespace App\Http\Resources\Ruta;

use App\Casts\AsPoint;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PedidoRutaResource extends JsonResource
{
  public function toArray(Request $request): array
  {
    return [
      'id' => $this->id,
      'codigo_barra' => $this->codigo_barra,
      'ubicacion_recojo' => AsPoint::serializeValue($this->ubicacion_recojo),
      'ubicacion_entrega' => AsPoint::serializeValue($this->ubicacion_entrega),
      'direccion_entrega_linea_1' => $this->direccion_entrega_linea_1,
      'paciente_nombre' => $this->paciente_nombre,
      'paciente_telefono' => $this->paciente_telefono,
      'observaciones' => $this->observaciones,
      'tipo_pedido' => $this->tipo_pedido,
      'estado' => $this->estado,
      'entregas' => [
        'orden_optimizado' => $this->orden_optimizado,
        'orden_personalizado' => $this->orden_personalizado,
        'orden_recojo' => $this->orden_recojo,
        'optimizado' => is_int($this->optimizado) ? (bool) $this->optimizado : $this->optimizado,
      ]
    ];
  }
}
