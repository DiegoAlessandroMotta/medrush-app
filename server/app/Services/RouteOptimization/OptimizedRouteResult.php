<?php

namespace App\Services\RouteOptimization;

use Carbon\Carbon;
use Illuminate\Support\Collection;

class OptimizedRouteResult
{
  public string $vehicleLabel;
  public ?Carbon $vehicleStartTime;
  public ?Carbon $vehicleEndTime;
  public ?string $routePolyline;
  public ?float $totalTravelDistanceMeters;
  public ?int $totalTravelDurationSeconds;

  /** @var Collection<int, OptimizedVisitResult> */
  public Collection $visits;

  /** @var Collection<string, OptimizedVisitResult> */
  public Collection $uniqueShipments;

  public function __construct(array $routeData)
  {
    $this->vehicleLabel = $routeData['vehicleLabel'];

    $this->vehicleStartTime = isset($routeData['vehicleStartTime'])
      ? Carbon::parse($routeData['vehicleStartTime'])
      : null;

    $this->vehicleEndTime = isset($routeData['vehicleEndTime'])
      ? Carbon::parse($routeData['vehicleEndTime'])
      : null;

    $this->visits = $this->parseAllVisits($routeData['visits'] ?? []);

    $this->uniqueShipments = $this->buildUniqueShipmentsCollection();

    $this->totalTravelDistanceMeters =
      $routeData['metrics']['travelDistanceMeters'] ?? null;
    $this->totalTravelDurationSeconds = $this->parseDurationToSeconds(
      $routeData['metrics']['travelDuration'] ?? '0s'
    );
    $this->routePolyline = $routeData['routePolyline']['points'] ?? null;
  }

  protected function parseAllVisits(array $visitsData): Collection
  {
    $allVisits = collect();

    foreach ($visitsData as $index => $visitData) {
      $isPickup = $visitData['isPickup'] ?? false;
      $visit = new OptimizedVisitResult($visitData, $index, $isPickup);
      $allVisits->push($visit);
    }

    return $allVisits;
  }

  protected function buildUniqueShipmentsCollection(): Collection
  {
    $uniqueShipmentsCollection = collect();
    $deliveryOrderCounter = 1;
    $pickupOrderCounter = 1;

    foreach ($this->visits as $visit) {
      $shipmentLabel = $visit->shipmentLabel;

      if (!$uniqueShipmentsCollection->has($shipmentLabel)) {
        $uniqueShipmentsCollection->put($shipmentLabel, clone $visit);
      }

      $uniqueShipment = $uniqueShipmentsCollection->get($shipmentLabel);

      if ($visit->isPickup) {
        if ($uniqueShipment->optimizedPickupOrder === null) {
          $uniqueShipment->setPickupOrder($pickupOrderCounter++);
        }
      } else {
        if ($uniqueShipment->optimizedDeliveryOrder === null) {
          $uniqueShipment->setDeliveryOrder($deliveryOrderCounter++);
        }
      }
    }

    return $uniqueShipmentsCollection;
  }

  protected function parseDurationToSeconds(string $duration): ?int
  {
    if (preg_match('/^(\d+)s$/', $duration, $matches)) {
      return (int) $matches[1];
    }

    return null;
  }
}
