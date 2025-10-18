<?php

namespace App\Services\RouteOptimization;

use Illuminate\Support\Collection;

class OptimizationResponse
{
  /** @var Collection<int, OptimizedRouteResult> */
  public Collection $optimizedRoutes;

  /** @var Collection<int, string> */
  public Collection $validationErrors;

  public function __construct(array $jsonResult)
  {
    $this->optimizedRoutes = collect($jsonResult['routes'] ?? [])
      ->filter(function ($routeData) {
        return isset($routeData['vehicleLabel']) && !empty($routeData['visits'] ?? []);
      })
      ->map(fn($routeData) => new OptimizedRouteResult($routeData));

    $this->validationErrors = collect($jsonResult['validationErrors'] ?? [])->map(
      fn($error) => $error['errorMessage'] ?? 'Unknown error'
    );
  }
}
