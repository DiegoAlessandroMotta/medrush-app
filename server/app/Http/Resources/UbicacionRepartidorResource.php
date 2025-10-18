<?php

namespace App\Http\Resources;

use App\Casts\AsPoint;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UbicacionRepartidorResource extends JsonResource
{
  public function toArray(Request $request): array
  {
    return [
      'id' => $this->id,
      'repartidor_id' => $this->repartidor_id,
      'pedido_id' => $this->pedido_id,
      'ruta_id' => $this->ruta_id,
      'ubicacion' => AsPoint::serializeValue($this->ubicacion),
      'precision_m' => $this->precision_m,
      'velocidad_ms' => $this->velocidad_ms,
      'direccion' => $this->direccion,
      'fecha_registro' => $this->fecha_registro,
      'created_at' => $this->created_at,
    ];
  }
}
