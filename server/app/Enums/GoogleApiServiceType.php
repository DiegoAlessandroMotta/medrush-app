<?php

namespace App\Enums;

enum GoogleApiServiceType: string
{
  case ROUTE_OPTIMIZATION_FLEETROUTING = 'route_optimization_fleetrouting';

  public function costPerRequest(): float
  {
    return match ($this) {
      self::ROUTE_OPTIMIZATION_FLEETROUTING => 0.03,
      default => 0.00,
    };
  }
}
