<?php

namespace App\Http\Resources;

use App\Enums\RolesEnum;
use App\Services\Disk\PrivateUploadsDiskService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
  public function toArray(Request $request): array
  {
    return [
      'id' => $this->id,
      'name' => $this->name,
      'email' => $this->email,
      'avatar' => PrivateUploadsDiskService::getSignedUrl($this->avatar_path),
      'is_active' => $this->is_active,
      'created_at' => $this->created_at,
      'updated_at' => $this->updated_at,
      'roles' => $this->whenLoaded('roles', fn() => $this->getRoleNames()),
      'perfil_repartidor' => $this->whenLoaded(
        RolesEnum::REPARTIDOR->getProfileRelationName(),
        fn() => new PerfilRepartidorResource($this->perfilRepartidor)
      ),
      'perfil_farmacia' => $this->whenLoaded(
        RolesEnum::FARMACIA->getProfileRelationName(),
        fn() => new PerfilFarmaciaResource($this->perfilFarmacia)
      ),
    ];
  }
}
