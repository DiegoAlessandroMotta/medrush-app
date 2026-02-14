<?php

namespace App\Http\Resources;

use App\Services\Disk\PrivateUploadsDiskService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PerfilRepartidorResource extends JsonResource
{
  public function toArray(Request $request): array
  {
    return [
      'farmacia_id' => $this->farmacia_id,
      'codigo_iso_pais' => $this->codigo_iso_pais,
      'telefono' => $this->telefono,
      'licencia_numero' => $this->licencia_numero,
      'licencia_vencimiento' => $this->licencia_vencimiento,
      'foto_licencia' => PrivateUploadsDiskService::getSignedUrl($this->foto_licencia_path),
      'foto_seguro_vehiculo' => PrivateUploadsDiskService::getSignedUrl($this->foto_seguro_vehiculo_path),
      'vehiculo_placa' => $this->vehiculo_placa,
      'vehiculo_marca' => $this->vehiculo_marca,
      'vehiculo_modelo' => $this->vehiculo_modelo,
      'vehiculo_codigo_registro' => $this->vehiculo_codigo_registro,
      'estado' => $this->estado,
      'verificado' => $this->verificado,
    ];
  }
}
