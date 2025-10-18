<?php

namespace App\Enums;

enum GoogleApiServiceType: string
{
  case ROUTE_OPTIMIZATION_FLEETROUTING = 'route_optimization_fleetrouting';
  case GEOCODING = 'geocoding';
  case DIRECTIONS = 'directions';

  public function costPerRequest(): float
  {
    return match ($this) {
      self::ROUTE_OPTIMIZATION_FLEETROUTING => 30 / 1000,
      self::GEOCODING => 5 / 1000,
      self::DIRECTIONS => 5 / 1000,
      default => 0.00,
    };
  }
}
