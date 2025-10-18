<?php

namespace App\Services\RouteOptimization;

use Carbon\Carbon;

class OptimizedVisitResult
{
  public string $shipmentLabel;
  public ?Carbon $startTime;
  public int $optimizedOrder;
  public bool $isPickup;
  public ?int $optimizedDeliveryOrder = null;
  public ?int $optimizedPickupOrder = null;

  public function __construct(array $visitData, int $index, bool $isPickup)
  {
    $this->shipmentLabel = $visitData['shipmentLabel'];
    $this->startTime = isset($visitData['startTime'])
      ? Carbon::parse($visitData['startTime'])
      : null;
    $this->optimizedOrder = $index;
    $this->isPickup = $isPickup;
  }

  public function setDeliveryOrder(int $order): void
  {
    $this->optimizedDeliveryOrder = $order;
  }

  public function setPickupOrder(int $order): void
  {
    $this->optimizedPickupOrder = $order;
  }
}
