<?php

namespace App\Enums;

enum RolesEnum: string
{
  case ADMINISTRADOR = 'administrador';
  case REPARTIDOR = 'repartidor';
  case FARMACIA = 'farmacia';

  public function getProfileRelationName(): ?string
  {
    return match ($this) {
      self::REPARTIDOR => 'perfilRepartidor',
      self::FARMACIA => 'perfilFarmacia',
      default => null,
    };
  }
}
