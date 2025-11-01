<?php

namespace App\Http\Resources\Pedido;

use App\Casts\AsPoint;
use App\Services\Disk\PrivateUploadsDiskService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PedidoRepartidorResource extends JsonResource
{
  public function toArray(Request $request): array
  {
    return [
      'id' => $this->id,
      'codigo_barra' => $this->codigo_barra,
      // 'farmacia_id' => $this->farmacia_id,
      // 'repartidor_id' => $this->repartidor_id,
      'paciente_nombre' => $this->paciente_nombre,
      'paciente_telefono' => $this->paciente_telefono,
      'paciente_email' => $this->paciente_email,
      'codigo_iso_pais_entrega' => $this->codigo_iso_pais_entrega,
      'direccion_entrega_linea_1' => $this->direccion_entrega_linea_1,
      'direccion_entrega_linea_2' => $this->direccion_entrega_linea_2,
      'ciudad_entrega' => $this->ciudad_entrega,
      'estado_region_entrega' => $this->estado_region_entrega,
      'codigo_postal_entrega' => $this->codigo_postal_entrega,
      'ubicacion_recojo' => AsPoint::serializeValue($this->ubicacion_recojo),
      'ubicacion_entrega' => AsPoint::serializeValue($this->ubicacion_entrega),
      'codigo_acceso_edificio' => $this->codigo_acceso_edificio,
      'medicamentos' => null,
      'tipo_pedido' => $this->tipo_pedido,
      'observaciones' => $this->observaciones,
      'requiere_firma_especial' => $this->requiere_firma_especial,
      'estado' => $this->estado,
      'firma_digital' => $this->firma_digital,
      'foto_entrega' => PrivateUploadsDiskService::getSignedUrl($this->foto_entrega_path),
      'firma_documento_consentimiento' => $this->firma_documento_consentimiento,
      'motivo_fallo' => $this->motivo_fallo,
      'observaciones_fallo' => $this->observaciones_fallo,
      'fecha_asignacion' => $this->fecha_asignacion,
      'fecha_recogida' => $this->fecha_recogida,
      'fecha_entrega' => $this->fecha_entrega,
      'tiempo_entrega_estimado' => $this->tiempo_entrega_estimado,
      'distancia_estimada' => $this->distancia_estimada,
      'created_at' => $this->created_at,
      'updated_at' => $this->updated_at,
      'farmacia' => $this->whenLoaded('farmacia', fn() => [
        'id' => $this->farmacia->id,
        'nombre' => $this->farmacia->nombre,
      ]),
      'repartidor' => $this->whenLoaded(RepartidorPedidoResource::$relationName, fn() => new RepartidorPedidoResource($this->repartidor)),
    ];
  }
}
